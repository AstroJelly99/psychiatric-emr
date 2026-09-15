// defaultErrorDialog() dulu SELALU nampilin "Coba ulangi lagi" apa pun
// penyebab errornya — makanya bug varchar(200) di kunjungan_section.dart
// keliatan cuma sebagai "Terjadi Kesalahan" tanpa petunjuk. Tes ini
// membuktikan dua hal: pesan asli ditampilkan kalau dikasih, dan 9
// pemanggil lain yang masih memanggil tanpa argumen (mis. manage_pasien.dart,
// obat_page.dart) tidak berubah perilakunya.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emr_homemade/utils/widgets/alert_dialogs.dart';

void main() {
  testWidgets('tanpa message -> tetap teks generik lama (backward compatible)',
      (tester) async {
    await tester.pumpWidget(MaterialApp(home: defaultErrorDialog()));
    await tester.pump();

    expect(find.text('Terjadi Kesalahan'), findsOneWidget);
    expect(find.text('Coba ulangi lagi'), findsOneWidget);
  });

  testWidgets('dengan message -> tampilkan alasan aslinya, bukan teks generik',
      (tester) async {
    const pesanAsli =
        'Gagal menambahkan kunjungan: PostgrestException(message: value too long for type character varying(200))';

    await tester.pumpWidget(
        MaterialApp(home: defaultErrorDialog(message: pesanAsli)));
    await tester.pump();

    expect(find.text('Terjadi Kesalahan'), findsOneWidget);
    expect(find.text(pesanAsli), findsOneWidget);
    expect(find.text('Coba ulangi lagi'), findsNothing);
  });
}
