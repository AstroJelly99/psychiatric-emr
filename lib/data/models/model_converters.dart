/// Konversi nilai antara Dart dan JSON PostgREST.
///
/// Dibuat karena tipe balikan berubah total dibanding mysql1:
///
/// | kolom            | mysql1                  | Supabase (JSON)              |
/// |------------------|-------------------------|------------------------------|
/// | tinyint(1)/bool  | int 1 / 0               | bool true / false            |
/// | text             | Blob (Uint8List)        | String                       |
/// | datetime         | DateTime (naif, lokal)  | String ISO-8601 (UTC)        |
/// | date             | DateTime                | String 'yyyy-MM-dd'          |
/// | int              | int                     | int                          |
///
/// Dua jebakan yang ditangani di sini:
///
/// 1. `map['is_active'] == 1` pada Supabase bernilai `false` untuk SEMUA
///    baris, karena `true == 1` di Dart adalah false. Tidak ada exception
///    yang dilempar — daftar hanya tampak kosong. Itu sebabnya [asBool] ada
///    dan tidak boleh dilewati.
/// 2. `timestamptz` dikirim ke server dalam UTC dan dibaca kembali sebagai
///    UTC. Kalau tidak di-`toLocal()` saat dibaca, jam yang tampil di UI
///    meleset 7 jam untuk WIB. [asDateTime] selalu mengembalikan waktu lokal.
library;

import 'package:intl/intl.dart';

/// Format tanggal untuk kolom bertipe `date` (bukan `timestamptz`).
final DateFormat _dateOnlyFormat = DateFormat('yyyy-MM-dd');

/// Membaca kolom boolean.
///
/// Menerima `bool` (bentuk Supabase) maupun `int` 1/0 dan String, supaya
/// data lama atau hasil RPC yang bertipe lain tidak diam-diam jadi false.
bool asBool(dynamic value, {bool fallback = false}) {
  if (value == null) return fallback;
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final v = value.trim().toLowerCase();
    if (v == 'true' || v == 't' || v == '1') return true;
    if (v == 'false' || v == 'f' || v == '0') return false;
  }
  return fallback;
}

/// Membaca kolom teks. Sudah selalu `String` di Supabase, tapi tetap
/// ditoleransi tipe lain supaya tidak melempar saat dipanggil atas hasil RPC.
String? asStringOrNull(dynamic value) {
  if (value == null) return null;
  if (value is String) return value;
  return value.toString();
}

/// Sama seperti [asStringOrNull] tapi menjamin non-null.
String asString(dynamic value, {String fallback = ''}) =>
    asStringOrNull(value) ?? fallback;

/// Membaca kolom integer. PostgREST bisa mengirim angka sebagai num/String
/// tergantung tipe kolom dan agregasi.
int asInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim()) ?? fallback;
  return fallback;
}

/// Membaca kolom `timestamptz` dan mengembalikannya dalam waktu LOKAL.
DateTime? asDateTimeOrNull(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value.isUtc ? value.toLocal() : value;
  final text = value.toString().trim();
  if (text.isEmpty) return null;
  final parsed = DateTime.tryParse(text);
  if (parsed == null) return null;
  return parsed.isUtc ? parsed.toLocal() : parsed;
}

/// Sama seperti [asDateTimeOrNull] tapi menjamin non-null.
DateTime asDateTime(dynamic value, {DateTime? fallback}) =>
    asDateTimeOrNull(value) ?? fallback ?? DateTime.now();

/// Membaca kolom `date` ('yyyy-MM-dd'). Tidak ada konversi zona waktu di
/// sini — tanggal lahir dan tanggal kunjungan adalah tanggal kalender, bukan
/// titik waktu. Menggeser zonanya justru bisa membuatnya mundur satu hari.
DateTime? asDateOrNull(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return DateTime(value.year, value.month, value.day);
  final text = value.toString().trim();
  if (text.isEmpty) return null;
  final parsed = DateTime.tryParse(text);
  if (parsed == null) return null;
  return DateTime(parsed.year, parsed.month, parsed.day);
}

/// Sama seperti [asDateOrNull] tapi menjamin non-null.
DateTime asDate(dynamic value, {DateTime? fallback}) =>
    asDateOrNull(value) ?? fallback ?? DateTime.now();

/// Menulis kolom `timestamptz`.
///
/// Selalu dikirim dalam UTC ber-suffix `Z`. Versi lama mengirim
/// `DateFormat('yyyy-MM-dd HH:mm:ss')` tanpa offset sama sekali; Postgres
/// akan menafsirkan string itu memakai timezone sesi (UTC di Supabase),
/// sehingga jam tersimpan meleset 7 jam untuk klinik di WIB.
String timestampToJson(DateTime value) => value.toUtc().toIso8601String();

/// Versi nullable dari [timestampToJson].
String? timestampToJsonOrNull(DateTime? value) =>
    value == null ? null : timestampToJson(value);

/// Menulis kolom `date`. Memakai komponen tanggal lokal apa adanya, tanpa
/// konversi UTC — lihat alasan di [asDateOrNull].
String dateToJson(DateTime value) => _dateOnlyFormat.format(value);

/// Versi nullable dari [dateToJson].
String? dateToJsonOrNull(DateTime? value) =>
    value == null ? null : dateToJson(value);
