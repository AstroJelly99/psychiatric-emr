# Taruh logo aplikasi di folder ini

## File yang dibutuhkan

| Nama file | Ukuran | Dipakai untuk |
|---|---|---|
| `logo.png` | **1024 × 1024 px**, PNG | ikon peluncur (yang muncul di layar HP) |
| `logo_foreground.png` | 1024 × 1024 px, PNG latar transparan | lapisan depan ikon adaptif Android 8+ |

`logo_foreground.png` boleh dilewati. Kalau tidak ada, hapus baris
`adaptive_icon_foreground` di `pubspec.yaml` dan Android akan memakai
`logo.png` apa adanya.

## Kenapa dua file

Android 8 ke atas memakai *adaptive icon*: sistem yang menentukan bentuknya
(bulat, kotak membulat, kotak), dan **memotong sekitar 25% di tiap tepi**.
Logo yang isinya memenuhi seluruh kanvas akan terpotong di HP tertentu.

Jadi untuk `logo_foreground.png`, letakkan gambar logo di **tengah, hanya
mengisi ±60-65% kanvas**, sisanya ruang kosong transparan. Ruang kosong itu
yang dimakan sistem, bukan logonya.

## Setelah file ditaruh

```bash
flutter pub get
dart run flutter_launcher_icons
```

Perintah kedua menimpa `android/app/src/main/res/mipmap-*/ic_launcher.png`.
Lalu build ulang — ikon lama masih tersimpan di cache launcher, jadi kalau
belum berubah, hapus dulu aplikasinya dari HP sebelum memasang yang baru.

## Memakai logo yang sama di dalam aplikasi

Sudah didaftarkan di `pubspec.yaml`, jadi bisa langsung dipakai:

```dart
Image.asset('assets/icon/logo.png', height: 32)
```

Tempat yang masuk akal: `lib/utils/widgets/appbar.dart` (mengganti
`Icon(Icons.medical_services)`) dan `lib/presentation/login/login_page.dart`.
