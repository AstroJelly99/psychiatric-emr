import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Jenis kegagalan yang bisa dialami satu operasi data.
///
/// Dipisah karena dokter perlu tahu bedanya "data gagal disimpan karena
/// internet mati" (boleh dicoba lagi, isian tidak salah) dengan "data ditolak
/// karena salah isi" (mencoba lagi tidak akan menolong).
enum RepositoryErrorKind {
  /// Tidak sampai ke server: internet mati, DNS gagal, timeout.
  network,

  /// Sampai ke server tapi ditolak: constraint, tipe salah, kolom tidak ada.
  query,

  /// Ditolak Row Level Security atau sesi login tidak valid/kedaluwarsa.
  permission,

  /// Khusus saat login: email/password tidak cocok.
  ///
  /// Dipisah dari [permission] supaya layar login bisa bilang "periksa
  /// ketikan Anda" tanpa mencampurnya dengan sesi kedaluwarsa di tengah jalan.
  credentials,

  /// Tidak terklasifikasi. Sengaja tidak dipukul rata jadi `network`.
  unknown,
}

/// Exception tunggal yang dilempar seluruh repository.
///
/// Semua repo melempar tipe ini, jadi provider yang sudah ada tetap bisa
/// menangkapnya dengan `catch (e)` dan memakai `"$e"` seperti sekarang —
/// signature method repo tidak berubah sama sekali.
class RepositoryException implements Exception {
  final RepositoryErrorKind kind;

  /// Pesan asli dari server/socket. Tidak pernah dibuang — pesan RLS
  /// ("new row violates row-level security policy") justru petunjuk paling
  /// berguna saat debugging.
  final String message;

  /// Kode Postgres/PostgREST kalau ada, mis. '23503' (FK), '42501' (RLS).
  final String? code;

  /// Keterangan singkat operasi yang gagal, untuk melacak asalnya.
  final String operation;

  const RepositoryException({
    required this.kind,
    required this.message,
    required this.operation,
    this.code,
  });

  bool get isNetworkError => kind == RepositoryErrorKind.network;
  bool get isPermissionError => kind == RepositoryErrorKind.permission;
  bool get isCredentialsError => kind == RepositoryErrorKind.credentials;

  /// Dipakai apa adanya oleh provider lewat interpolasi `"$e"`, jadi
  /// teksnya ditulis untuk dibaca dokter, bukan hanya untuk log.
  @override
  String toString() {
    switch (kind) {
      case RepositoryErrorKind.network:
        return 'Tidak ada koneksi ke server. Data BELUM tersimpan. '
            'Periksa koneksi internet lalu coba lagi. [$operation: $message]';
      case RepositoryErrorKind.permission:
        return 'Akses ditolak oleh server. Coba keluar lalu masuk kembali. '
            '[$operation${code != null ? ' $code' : ''}: $message]';
      case RepositoryErrorKind.credentials:
        return 'Username atau password salah.';
      case RepositoryErrorKind.query:
        return 'Data ditolak server. Periksa kembali isian. '
            '[$operation${code != null ? ' $code' : ''}: $message]';
      case RepositoryErrorKind.unknown:
        return 'Terjadi kesalahan tak terduga. [$operation: $message]';
    }
  }
}

/// Wrapper tipis di atas Supabase client.
///
/// Menggantikan wrapper MySQL lama. Tidak lagi menyediakan `query(sql)` —
/// tidak ada raw SQL yang dikirim dari aplikasi; semua lewat query builder
/// PostgREST atau RPC function di supabase/migrations/0002_query_layer.sql.
class DatabaseHelper {
  const DatabaseHelper._();

  static SupabaseClient get client => Supabase.instance.client;

  /// Shortcut ke satu tabel.
  static SupabaseQueryBuilder table(String name) => client.from(name);

  /// Menetralkan wildcard yang diketik pengguna sebelum masuk ke `.ilike()`.
  ///
  /// Di versi MySQL, `%` atau `_` yang diketik dokter ikut diperlakukan
  /// sebagai wildcard. Sekarang jadi karakter biasa, supaya hasil pencarian
  /// tidak melebar tanpa disengaja.
  static String escapeLike(String input) =>
      input.replaceAll('%', r'\%').replaceAll('_', r'\_');

  /// Membungkus satu operasi Supabase dan menerjemahkan kegagalannya jadi
  /// [RepositoryException] dengan [RepositoryErrorKind] yang tepat.
  ///
  /// Sengaja TIDAK menangkap `Exception` generik lalu menelannya: setiap
  /// cabang di bawah menangkap tipe spesifik dan selalu meneruskan message
  /// aslinya. Yang tidak dikenali jadi `unknown`, bukan diklaim sebagai
  /// masalah jaringan.
  static Future<T> run<T>(
    String operation,
    Future<T> Function() action, {
    bool isSignIn = false,
  }) async {
    try {
      return await action();
    } on PostgrestException catch (e) {
      throw RepositoryException(
        kind: _kindFromPostgrest(e),
        message: [e.message, e.details, e.hint]
            .where((s) => s != null && s.toString().trim().isNotEmpty)
            .join(' | '),
        code: e.code,
        operation: operation,
      );
    } on AuthException catch (e) {
      // Saat login, AuthException hanya bisa berarti kredensial ditolak.
      // Di luar login, artinya sesi bermasalah — dua hal yang butuh tindakan
      // berbeda dari dokter, jadi tidak boleh disamakan.
      throw RepositoryException(
        kind: isSignIn
            ? RepositoryErrorKind.credentials
            : RepositoryErrorKind.permission,
        message: e.message,
        code: e.statusCode,
        operation: operation,
      );
    } on SocketException catch (e) {
      // Internet mati, DNS gagal, host tidak bisa dijangkau.
      throw RepositoryException(
        kind: RepositoryErrorKind.network,
        message: e.message.isEmpty ? 'gagal menghubungi server' : e.message,
        operation: operation,
      );
    } on HttpException catch (e) {
      throw RepositoryException(
        kind: RepositoryErrorKind.network,
        message: e.message,
        operation: operation,
      );
    } on TimeoutException catch (e) {
      throw RepositoryException(
        kind: RepositoryErrorKind.network,
        message: e.message ?? 'server tidak merespons tepat waktu',
        operation: operation,
      );
    } on RepositoryException {
      // Sudah diterjemahkan di lapisan dalam, jangan dibungkus dua kali.
      rethrow;
    } catch (e) {
      // Sisanya (mis. ClientException dari package:http saat koneksi putus
      // di tengah) tidak punya tipe stabil untuk di-catch, jadi dikenali
      // dari isi pesannya. Kalau tetap tidak dikenali -> unknown.
      final text = e.toString();
      final looksLikeNetwork = text.contains('SocketException') ||
          text.contains('ClientException') ||
          text.contains('Connection closed') ||
          text.contains('Connection reset') ||
          text.contains('Failed host lookup');
      throw RepositoryException(
        kind: looksLikeNetwork
            ? RepositoryErrorKind.network
            : RepositoryErrorKind.unknown,
        message: text,
        operation: operation,
      );
    }
  }

  static RepositoryErrorKind _kindFromPostgrest(PostgrestException e) {
    final code = e.code ?? '';
    final message = e.message.toLowerCase();

    // 42501 = insufficient_privilege; PostgREST juga memakai 401/403 untuk
    // JWT bermasalah. Pesan RLS-nya sendiri selalu memuat frasa di bawah.
    if (code == '42501' ||
        code == '401' ||
        code == '403' ||
        message.contains('row-level security') ||
        message.contains('row level security') ||
        message.contains('jwt')) {
      return RepositoryErrorKind.permission;
    }
    return RepositoryErrorKind.query;
  }
}
