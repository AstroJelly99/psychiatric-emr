import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_service.dart';

/// Keluar otomatis kalau aplikasi ditinggal terlalu lama.
///
/// Yang dihitung adalah lama aplikasi TIDAK DIBUKA, bukan lama layar diam.
/// Bedanya penting di ruang praktek: dokter yang membaca satu layar riwayat
/// selama 15 menit tidak boleh tiba-tiba terlempar ke halaman login, sementara
/// HP yang ditinggal di meja lalu diambil orang lain setelah setengah jam
/// harus meminta login lagi.
///
/// Caranya menyimpan CAP WAKTU, bukan menyalakan Timer. Timer mati bersama
/// prosesnya, dan Android bebas membunuh proses aplikasi yang di latar
/// belakang kapan saja — jadi Timer akan diam-diam gagal persis pada kasus
/// yang paling ingin dijaga. Cap waktu di SharedPreferences bertahan melewati
/// proses yang dibunuh, bahkan melewati HP yang dimatikan.
class SessionTimeout {
  const SessionTimeout._();

  /// Diambil 10 menit sesuai permintaan. Diletakkan sebagai konstanta supaya
  /// ada satu tempat untuk mengubahnya.
  static const Duration maxIdle = Duration(minutes: 10);

  static const String _key = 'last_left_app_at';

  /// Dicatat saat aplikasi ditinggalkan (masuk latar belakang).
  static Future<void> markLeft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, DateTime.now().millisecondsSinceEpoch);
  }

  /// Dihapus saat sesi dimulai atau diakhiri, supaya cap waktu sisa dari sesi
  /// sebelumnya tidak ikut menghakimi sesi yang baru.
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  /// Berapa lama aplikasi terakhir ditinggalkan. `null` kalau belum pernah
  /// tercatat (mis. baru dipasang, atau baru saja login).
  static Future<Duration?> awayFor() async {
    final prefs = await SharedPreferences.getInstance();
    final int? at = prefs.getInt(_key);
    if (at == null) return null;

    final away = DateTime.now()
        .difference(DateTime.fromMillisecondsSinceEpoch(at));
    // Cap waktu di masa depan berarti jam perangkat mundur setelah cap dibuat.
    // Diperlakukan sebagai "belum lama", bukan angka negatif yang menyesatkan.
    return away.isNegative ? Duration.zero : away;
  }

  /// Dipanggil saat aplikasi dibuka lagi dan saat aplikasi baru dijalankan.
  ///
  /// Mengembalikan true kalau sesi memang diakhiri, supaya pemanggil bisa
  /// memberi tahu penggunanya alih-alih membuat mereka bertanya-tanya kenapa
  /// tiba-tiba kembali ke halaman login.
  static Future<bool> enforce() async {
    if (!AuthService.isLoggedIn) {
      // Tidak ada sesi untuk diakhiri; cap waktunya dibersihkan supaya tidak
      // menua dan mengganggu login berikutnya.
      await clear();
      return false;
    }

    final Duration? away = await awayFor();
    if (away == null || away < maxIdle) return false;

    await AuthService.logout();
    await clear();
    return true;
  }
}

/// Memasang [SessionTimeout] ke daur hidup aplikasi.
///
/// Dibungkuskan di sekitar `MaterialApp` supaya satu-satunya yang perlu tahu
/// soal daur hidup adalah widget ini, bukan tiap halaman.
class SessionGuard extends StatefulWidget {
  const SessionGuard({required this.child, super.key});

  final Widget child;

  @override
  State<SessionGuard> createState() => _SessionGuardState();
}

class _SessionGuardState extends State<SessionGuard>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Menutup kasus proses yang sempat dibunuh Android: `resumed` tidak akan
    // pernah datang untuk pembukaan yang ini, jadi pemeriksaannya dilakukan
    // sekali saat mulai.
    SessionTimeout.enforce();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        SessionTimeout.enforce();
      case AppLifecycleState.inactive:
        // Sengaja diabaikan. `inactive` juga muncul untuk hal-hal sesaat
        // seperti menarik panel notifikasi atau menerima telepon; mencatatnya
        // sebagai "ditinggalkan" tidak salah, tapi juga tidak menambah apa pun
        // karena `paused` selalu menyusul kalau memang benar-benar keluar.
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        SessionTimeout.markLeft();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
