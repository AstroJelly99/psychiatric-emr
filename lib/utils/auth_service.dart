import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Status login aplikasi.
///
/// Sebelumnya class ini menyimpan flag `isLoggedIn` sendiri di
/// SharedPreferences. Itu berbahaya sekarang: flag lokal bisa bilang "sudah
/// login" padahal sesi Supabase sudah kedaluwarsa, dan hasilnya UI terbuka
/// tapi setiap query ditolak RLS tanpa penjelasan.
///
/// Jadi sekarang hanya ada SATU sumber kebenaran: sesi Supabase.
/// SharedPreferences tetap dipakai, tapi hanya sebagai cache nama pengguna
/// untuk kolom audit `created_by` — bukan untuk menentukan status login.
class AuthService {
  const AuthService._();

  static GoTrueClient get _auth => Supabase.instance.client.auth;

  /// Sesi aktif, atau null kalau belum/tidak lagi login.
  static Session? get currentSession => _auth.currentSession;

  /// Sinkron, sengaja bukan Future: redirect GoRouter harus bisa memutuskan
  /// tanpa menunggu I/O. Sesi sudah dipulihkan dari penyimpanan lokal saat
  /// `Supabase.initialize()` di main.dart.
  static bool get isLoggedIn => currentSession != null;

  /// UID Supabase Auth dari pengguna yang sedang login.
  ///
  /// Inilah kunci profil di `master_user` (kolom `user_id` adalah FK ke
  /// `auth.users(id)`).
  static String? get currentUserId => _auth.currentUser?.id;

  /// Aliran perubahan status login (masuk, keluar, token diperbarui).
  static Stream<AuthState> get onAuthStateChange => _auth.onAuthStateChange;

  /// Keluar dari aplikasi.
  ///
  /// `signOut()` dipanggil lebih dulu dan tidak boleh dilewati: menghapus
  /// data lokal saja akan membuat "logout" jadi palsu — sesinya masih hidup
  /// dan token masih bisa dipakai.
  static Future<void> logout() async {
    try {
      await _auth.signOut();
    } finally {
      // Cache lokal tetap dibersihkan meskipun signOut gagal (mis. internet
      // mati), supaya nama pengguna lama tidak nyangkut di sesi berikutnya.
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('username');
      // Cap waktu "terakhir meninggalkan aplikasi" ikut dibuang. Kalau
      // ditinggal, cap lama itu akan menghakimi sesi berikutnya: login baru
      // bisa langsung dianggap kedaluwarsa begitu aplikasi dibuka lagi.
      await prefs.remove('last_left_app_at');
    }
  }
}

/// Menjembatani [AuthService.onAuthStateChange] ke `refreshListenable`
/// GoRouter.
///
/// Tanpa ini, redirect hanya dievaluasi saat navigasi terjadi — sesi yang
/// berakhir di tengah pemakaian tidak akan memulangkan dokter ke layar login
/// sampai dia kebetulan berpindah halaman.
class AuthStateNotifier extends ChangeNotifier {
  AuthStateNotifier() {
    _subscription = AuthService.onAuthStateChange.listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
