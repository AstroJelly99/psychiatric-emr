import '../models/model_converters.dart';
import '../models/user_model.dart';
import '../../database/database_helper.dart';

class UserRepo {
  static const String _table = 'master_user';

  // `master_user.user_id` adalah FK ke `auth.users(id)`, jadi baris ini
  // cuma bisa masuk kalau akun Auth-nya sudah dibuat lebih dulu lewat
  // Supabase Dashboard. Pembuatan akun dari aplikasi sengaja tidak dibuka:
  // butuh service_role key, yang tidak boleh masuk ke .exe.
  static Future<void> insert(UserModel user) {
    return DatabaseHelper.run('insert user', () async {
      await DatabaseHelper.table(_table).insert({
        'user_id': user.userId,
        'username': user.username,
        'name': user.name,
        'role': user.role,
        'is_active': user.isActive,
        'create_date': timestampToJson(user.createDate),
        'created_by': user.createdBy,
      });
    });
  }

  // Kolom `password` sengaja tidak ikut: sudah tidak ada di server, ganti
  // password sekarang lewat Supabase Auth.
  static Future<void> update(UserModel user) {
    return DatabaseHelper.run('update user', () async {
      await DatabaseHelper.table(_table).update({
        'username': user.username,
        'name': user.name,
        'role': user.role,
        'is_active': user.isActive,
        'modify_date': timestampToJson(DateTime.now()),
        'modified_by': user.modifiedBy,
      }).eq('user_id', user.userId);
    });
  }

  static Future<List<UserModel>> getAll({int limit = 50, int offset = 0}) {
    return DatabaseHelper.run('getAll user', () async {
      final rows = await DatabaseHelper.table(_table)
          .select()
          .eq('is_active', true)
          .range(offset, offset + limit - 1);
      return rows.map((row) => UserModel.fromMap(row)).toList();
    });
  }

  static Future<UserModel?> getById(String id) {
    return DatabaseHelper.run('getById user', () async {
      final row = await DatabaseHelper.table(_table)
          .select()
          .eq('user_id', id)
          .maybeSingle();
      if (row == null) return null;
      return UserModel.fromMap(row);
    });
  }

  static Future<void> delete(String id, String modifiedBy) {
    return DatabaseHelper.run('delete user', () async {
      await DatabaseHelper.table(_table).update({
        'is_active': false,
        'modify_date': timestampToJson(DateTime.now()),
        'modified_by': modifiedBy,
      }).eq('user_id', id);
    });
  }

  static Future<List<UserModel>> searchByUsername(String keyword) {
    return DatabaseHelper.run('searchByUsername user', () async {
      final rows = await DatabaseHelper.table(_table)
          .select()
          // ilike, bukan like: Postgres LIKE case-sensitive (beda dari MySQL).
          .ilike('username', '%${DatabaseHelper.escapeLike(keyword)}%')
          .eq('is_active', true);
      return rows.map((row) => UserModel.fromMap(row)).toList();
    });
  }

  static Future<bool> exists(String id) {
    return DatabaseHelper.run('exists user', () async {
      final rows = await DatabaseHelper.table(_table)
          .select('user_id')
          .eq('user_id', id)
          .limit(1);
      return rows.isNotEmpty;
    });
  }

  /// Mencari profil berdasarkan user id Supabase Auth.
  ///
  /// `master_user.user_id` adalah FK ke `auth.users(id)`, jadi UID sesi
  /// Supabase langsung menjadi kunci profil — tidak perlu lagi mencari
  /// berdasarkan username.
  static Future<UserModel?> getByAuthId(String authUserId) => getById(authUserId);

  /// Domain email sintetis untuk memetakan username menjadi email Auth.
  ///
  /// Disepakati sejak langkah 1: dokter tetap mengetik "username" di layar
  /// login, dan aplikasi yang menambahkan domainnya. Akun di Supabase Auth
  /// harus didaftarkan dengan email yang mengikuti format ini persis.
  static const String emailDomain = 'klinik.local';

  /// Mengubah isi field "username" di layar login menjadi email Auth.
  ///
  /// Kalau dokter terlanjur mengetik alamat email lengkap, dipakai apa
  /// adanya — supaya tidak berubah jadi `dokter@klinik.local@klinik.local`.
  static String usernameToEmail(String username) {
    final trimmed = username.trim();
    return trimmed.contains('@') ? trimmed : '$trimmed@$emailDomain';
  }

  /// Login lewat Supabase Auth, lalu ambil profil dari `master_user`.
  ///
  /// Signature dipertahankan persis seperti versi MySQL supaya layar login
  /// tidak perlu berubah, tapi isinya sudah berbeda total:
  ///   1. username dipetakan jadi `<username>@klinik.local`
  ///   2. `signInWithPassword()` — inilah yang membuat sesi jadi
  ///      `authenticated`, sehingga RLS mulai mengizinkan query
  ///   3. profil diambil lewat `auth.currentUser!.id`, bukan username
  ///
  /// Melempar [RepositoryException] dengan kind yang membedakan salah
  /// password (`credentials`) dari internet mati (`network`). Mengembalikan
  /// null hanya sebagai jaring pengaman; jalur normal selalu non-null.
  static Future<UserModel?> authenticate(String username, String password) {
    return DatabaseHelper.run(
      'login',
      () async {
        final response = await DatabaseHelper.client.auth.signInWithPassword(
          email: usernameToEmail(username),
          password: password,
        );

        final authUserId = response.user?.id;
        if (authUserId == null) {
          throw const RepositoryException(
            kind: RepositoryErrorKind.credentials,
            operation: 'login',
            message: 'Server tidak mengembalikan sesi.',
          );
        }

        // Sesi sudah hidup di titik ini. Kalau langkah di bawah gagal, sesi
        // WAJIB dibatalkan lagi — kalau tidak, router menganggap sudah login
        // padahal aplikasi tidak punya profil dan role untuk dipakai.
        final UserModel? profile;
        try {
          profile = await getByAuthId(authUserId);
        } catch (_) {
          await DatabaseHelper.client.auth.signOut();
          rethrow;
        }

        if (profile == null) {
          await DatabaseHelper.client.auth.signOut();
          throw const RepositoryException(
            kind: RepositoryErrorKind.permission,
            operation: 'login',
            message: 'Akun ini belum punya baris di master_user. '
                'Tambahkan profilnya lewat Supabase Dashboard dengan user_id '
                'yang sama dengan UID akun Auth-nya.',
          );
        }

        // Versi MySQL menyaring `AND is_active = 1`. Dipertahankan: akun yang
        // sudah dinonaktifkan tidak boleh masuk hanya karena password lamanya
        // masih valid di Auth.
        if (!profile.isActive) {
          await DatabaseHelper.client.auth.signOut();
          throw const RepositoryException(
            kind: RepositoryErrorKind.permission,
            operation: 'login',
            message: 'Akun ini sudah dinonaktifkan.',
          );
        }

        return profile;
      },
      isSignIn: true,
    );
  }
}
