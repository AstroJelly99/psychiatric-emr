// Tes untuk pola caching halaman yang dipakai
// _PanelPageState._pageAt (lib/presentation/panel/panel_page.dart):
//
//   - halaman yang BELUM pernah dibuka -> placeholder kosong, provider-nya
//     tidak pernah dibuat (tidak nembak query sama sekali)
//   - halaman yang SUDAH pernah dibuka -> tetap hidup di IndexedStack, jadi
//     initState-nya cuma jalan SEKALI walau dibuka-tutup berkali-kali
//
// _pageAt sendiri privat dan terikat ke 9 provider asli (butuh Supabase),
// jadi tidak bisa dites langsung tanpa network. Tes ini menjalankan ULANG
// predikat yang SAMA PERSIS (`index == currentPage || cache.containsKey`)
// di atas widget hitung-inisialisasi tiruan, untuk membuktikan pola
// "dibangun sekali, sisanya cuma disembunyikan" itu benar-benar berlaku
// pada IndexedStack milik Flutter.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Widget yang menghitung berapa kali dirinya BENAR-BENAR diinisialisasi
/// (initState), bukan berapa kali build() dipanggil — supaya kelihatan
/// jelas kalau widgetnya dibongkar-pasang ulang (state hilang) vs cuma
/// disembunyikan (state tetap).
class _CountingPage extends StatefulWidget {
  final int index;
  final List<int> initCounts;
  const _CountingPage({required this.index, required this.initCounts});

  @override
  State<_CountingPage> createState() => _CountingPageState();
}

class _CountingPageState extends State<_CountingPage> {
  @override
  void initState() {
    super.initState();
    widget.initCounts[widget.index]++;
  }

  @override
  Widget build(BuildContext context) => Text('page ${widget.index}');
}

void main() {
  testWidgets(
      'halaman yang belum pernah dibuka tidak dibangun sama sekali (placeholder kosong)',
      (tester) async {
    final initCounts = List.filled(3, 0);
    final Map<int, Widget> cache = {};
    int currentPage = 0;

    Widget pageAt(int index) {
      if (index == currentPage || cache.containsKey(index)) {
        return cache.putIfAbsent(
            index, () => _CountingPage(index: index, initCounts: initCounts));
      }
      return const SizedBox.shrink();
    }

    await tester.pumpWidget(MaterialApp(
      home: IndexedStack(
        index: currentPage,
        children: [for (int i = 0; i < 3; i++) pageAt(i)],
      ),
    ));

    expect(initCounts, [1, 0, 0],
        reason: 'cuma halaman aktif (0) yang boleh dibangun; '
            '1 dan 2 belum pernah dibuka jadi harus tetap 0');
  });

  testWidgets(
      'halaman yang sudah pernah dibuka TIDAK di-init ulang saat dibuka lagi',
      (tester) async {
    final initCounts = List.filled(3, 0);
    final Map<int, Widget> cache = {};
    int currentPage = 0;

    Widget pageAt(int index) {
      if (index == currentPage || cache.containsKey(index)) {
        return cache.putIfAbsent(
            index, () => _CountingPage(index: index, initCounts: initCounts));
      }
      return const SizedBox.shrink();
    }

    late StateSetter setPage;

    await tester.pumpWidget(MaterialApp(
      home: StatefulBuilder(builder: (context, setState) {
        setPage = setState;
        return IndexedStack(
          index: currentPage,
          children: [for (int i = 0; i < 3; i++) pageAt(i)],
        );
      }),
    ));
    expect(initCounts, [1, 0, 0]);

    // Pindah ke halaman 1 (pertama kali -> init sekali), lalu balik ke 0.
    setPage(() => currentPage = 1);
    await tester.pump();
    expect(initCounts, [1, 1, 0]);

    setPage(() => currentPage = 0);
    await tester.pump();
    expect(initCounts, [1, 1, 0],
        reason: 'balik ke halaman 0 yang sudah pernah dibuka TIDAK boleh '
            'menaikkan hitungan init-nya lagi — inilah "instan, tanpa reload" '
            'yang diklaim');

    // Bolak-balik beberapa kali lagi -> tetap tidak berubah.
    setPage(() => currentPage = 1);
    await tester.pump();
    setPage(() => currentPage = 0);
    await tester.pump();
    setPage(() => currentPage = 1);
    await tester.pump();
    expect(initCounts, [1, 1, 0],
        reason: 'berapa kali pun bolak-balik, tiap halaman cuma di-init '
            'sekali seumur hidup widget-nya');

    // Halaman 2 belum pernah disentuh -> masih 0.
    expect(initCounts[2], 0);
    setPage(() => currentPage = 2);
    await tester.pump();
    expect(initCounts, [1, 1, 1],
        reason: 'begitu pertama kali dibuka, barulah halaman 2 di-init');
  });
}
