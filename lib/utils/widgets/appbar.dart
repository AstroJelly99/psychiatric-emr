import 'package:flutter/material.dart';
import 'package:emr_homemade/domain/appbar/appbar_provider.dart';
import 'package:google_fonts/google_fonts.dart';

AppBar mainAppBar(BuildContext context, AppBarProvider prov,
    {required void Function() onAccountPressed}) {
  return AppBar(
    backgroundColor: Colors.white,
    elevation: 1, // kasih shadow tipis biar keliatan dipisah
    surfaceTintColor: Colors.white,
    titleSpacing: 24,
    automaticallyImplyLeading: false,
    title: LayoutBuilder(
      builder: (context, constraints) {
        final bool narrow = constraints.maxWidth <= 640;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Untuk memakai logo sendiri, ganti baris ini dengan:
            //   Image.asset('assets/icon/logo.png', height: 26)
            // File-nya belum ada, jadi ikon bawaan dipertahankan dulu —
            // Image.asset ke berkas yang tidak ada akan menampilkan kotak
            // error merah di seluruh halaman, bukan sekadar gambar kosong.
            const Icon(Icons.medical_services, color: Colors.blue, size: 26),
            const SizedBox(width: 6),
            // Flexible + ellipsis: "EMR Homemade" jauh lebih panjang dari
            // "EMR", dan di 360dp ruang judul sudah dibagi dengan nama
            // pengguna serta tombol keluar di sisi kanan.
            Flexible(
              child: Text(
                'EMR Homemade',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.bold,
                  fontSize: narrow ? 20 : 26,
                  height: 0.9,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 6),
            narrow
                ? const SizedBox()
                : Text(
                    'Electronic Medical Record',
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w200,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
            SizedBox(width: narrow ? 4 : 30),
          ],
        );
      },
    ),
    centerTitle: false,
    // Di HP dulu ini tombol hamburger yang membuka endDrawer, padahal isi
    // drawer itu hanya nama pengguna + satu tombol Logout. Dua ketukan dan
    // satu panel penuh untuk satu aksi. Sekarang aksinya langsung: nama
    // pengguna tetap terlihat, dan Logout jadi tombol tersendiri.
    actions: MediaQuery.of(context).size.width <= 640
        ? <Widget>[
            // Nama pengguna sengaja TIDAK ditampilkan di app bar HP.
            //
            // AppBar memberi ruang ke `actions` lebih dulu, baru sisanya ke
            // `title`. Dengan nama pengguna di sini, judul "EMR Homemade"
            // menyusut jadi lebar 0 (terukur di 320dp dan 360dp) — dan tanpa
            // error apa pun, karena Flexible menyusutkannya diam-diam.
            // Dibatasi 96px pun judulnya masih terpotong jadi "EMR Hom…".
            //
            // Identitasnya tidak hilang: dialog konfirmasi keluar menyebut
            // "Anda akan keluar sebagai <nama>". Jadi yang dikorbankan hanya
            // pengulangan, bukan informasi.
            IconButton(
              onPressed: onAccountPressed,
              tooltip: 'Keluar dari akun',
              icon: Icon(Icons.logout_rounded,
                  color: Colors.red.shade600, size: 24),
            ),
            const SizedBox(width: 4),
          ]
        : <Widget>[
            
            TextButton(
              onPressed: onAccountPressed,
              child: Row(
                children: [
                  const Icon(Icons.account_circle_outlined,
                      color: Colors.black),
                  const SizedBox(width: 4),
                  Text(
                    prov.username,
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w200,
                      fontSize: 18,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
          ],
  );
}