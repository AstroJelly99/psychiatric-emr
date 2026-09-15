import 'package:flutter/material.dart';
import 'package:emr_homemade/config/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // initialize() TIDAK membuka koneksi ke server — cuma menyiapkan client
    // dan memulihkan sesi lokal. Jadi ErrorApp di bawah berarti "config
    // salah", BUKAN "server tidak bisa dihubungi"; internet putus muncul
    // per query sebagai RepositoryException (lihat database_helper.dart).
    // `publishableKey`: nama baru untuk `anonKey` (deprecated), nilainya
    // tetap anon/public key yang sama.
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.anonKey,
    );
    debugPrint('Supabase client siap');
    runApp(const MyApp());
  } catch (e) {
    debugPrint('Gagal menyiapkan koneksi Supabase: $e');
    runApp(const ErrorApp());
  }
}

class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 20),
              const Text(
                'Gagal Menyiapkan Koneksi Database',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Periksa isi lib/config/supabase_config.dart (URL dan anon key).\n'
                'Kalau internet yang bermasalah, pesannya akan muncul saat membuka data,\n'
                'bukan di layar ini.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  main();
                },
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}