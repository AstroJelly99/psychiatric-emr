import 'package:flutter/material.dart';
import 'package:emr_homemade/utils/auth_service.dart';
import 'package:emr_homemade/utils/widgets/alert_dialogs.dart';
import 'package:emr_homemade/utils/routes.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppBarProvider extends ChangeNotifier {
  AppBarProvider() {
    loadUserDataPreferences();
  }

  String username = 'Guest';
  bool isFetch = false;

  Future<void> loadUserDataPreferences() async {
    isFetch = true;
    notifyListeners();

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    username = prefs.getString("username") ?? "Guest";

    isFetch = false;
    notifyListeners();
  }

  Future<void> logout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) =>
          confirmLogoutDialog(context: context, username: username),
    );
    
    if (shouldLogout == true) {
      // AuthService.logout() sekarang memanggil Supabase signOut() lebih
      // dulu, baru membersihkan cache lokal. Urutan ini penting: kalau
      // hanya flag lokal yang dihapus, sesi Supabase tetap hidup dan
      // "logout" jadi palsu.
      await AuthService.logout();

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      username = 'Guest';
      notifyListeners();

      if (context.mounted) {
        context.go(Routes.login);
      }
    }
  }
}