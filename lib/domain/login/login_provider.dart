import 'package:flutter/material.dart';
import 'package:emr_homemade/data/repositories/user_repo.dart';
import 'package:emr_homemade/database/database_helper.dart';
import 'package:emr_homemade/utils/routes.dart';
import 'package:emr_homemade/utils/session_timeout.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginProvider with ChangeNotifier {
  final BuildContext context;
  
  LoginProvider(this.context) {
    _loadRememberedCredentials();
  }

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isLogging = false;
  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  String _errorMessage = '';

  bool get isLogging => _isLogging;
  bool get isPasswordVisible => _isPasswordVisible;
  bool get rememberMe => _rememberMe;
  String get errorMessage => _errorMessage;

  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  void setRememberMe(bool value) {
    _rememberMe = value;
    notifyListeners();
  }

  Future<void> _loadRememberedCredentials() async {
    // TODO: Implement load from shared preferences
    // For now, we'll leave this empty
  }

  Future<void> _saveCredentials() async {
    if (_rememberMe) {
      // TODO: Implement save to shared preferences
    }
  }

  Future<void> login() async {
    if (usernameController.text.isEmpty || passwordController.text.isEmpty) {
      _errorMessage = 'Username dan password harus diisi';
      notifyListeners();
      return;
    }

    _isLogging = true;
    _errorMessage = '';
    notifyListeners();

    try {
      // Field di layar tetap "username"; UserRepo.authenticate yang memetakan
      // isinya jadi '<username>@klinik.local' sebelum dikirim ke Supabase.
      final user = await UserRepo.authenticate(
        usernameController.text.trim(),
        passwordController.text.trim(),
      );

      if (user != null) {
        // Nama yang disimpan diambil dari profil master_user, bukan dari apa
        // yang diketik dokter. Ini dipakai 11 provider lain sebagai nilai
        // `created_by`, jadi harus konsisten dengan isi database.
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', user.username);

        // Sesi baru dimulai dengan hitungan menganggur yang bersih. Tanpa ini,
        // cap waktu sisa dari sesi sebelumnya masih tersimpan, dan begitu
        // aplikasi ditutup lalu dibuka lagi, sesi yang baru saja dibuat bisa
        // langsung dianggap kedaluwarsa.
        await SessionTimeout.clear();

        await _saveCredentials();

        // Tidak ada lagi AuthService.setLoggedIn(): status login sekarang
        // dibaca langsung dari sesi Supabase, supaya tidak ada dua sumber
        // kebenaran yang bisa berbeda.
        if (context.mounted) {
          GoRouter.of(context).go(Routes.panel);
        }
      } else {
        _errorMessage = 'Username atau password salah';
      }
    } on RepositoryException catch (e) {
      // Tiga sebab kegagalan yang butuh tindakan berbeda dari dokter.
      switch (e.kind) {
        case RepositoryErrorKind.credentials:
          _errorMessage = 'Username atau password salah. Periksa ketikan Anda.';
        case RepositoryErrorKind.network:
          _errorMessage =
              'Tidak ada koneksi ke server. Periksa internet lalu coba lagi.';
        case RepositoryErrorKind.permission:
        case RepositoryErrorKind.query:
        case RepositoryErrorKind.unknown:
          _errorMessage = 'Gagal masuk: ${e.message}';
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
    } finally {
      _isLogging = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}