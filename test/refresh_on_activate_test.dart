// Tes untuk RefreshOnActivate (lib/presentation/panel/refresh_on_activate.dart)
// — mekanisme yang menjamin halaman yang di-cache PanelPage (IndexedStack)
// tetap menarik data baru tiap kali dibuka ulang, bukan beku selamanya.
//
// Skenario yang dites persis skenario yang dikhawatirkan: tambah pasien di
// halaman lain, balik ke halaman yang sudah pernah dibuka -> harus fetch
// ulang, bukan diam.
//
// Tidak menyentuh Supabase/network sama sekali: providernya cuma
// ChangeNotifier tiruan yang menghitung berapa kali refresh dipanggil.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:emr_homemade/domain/panel/panel_provider.dart';
import 'package:emr_homemade/presentation/panel/refresh_on_activate.dart';

class _FakePageProvider extends ChangeNotifier {
  int refreshCalls = 0;

  Future<void> refreshData() async {
    refreshCalls++;
    notifyListeners();
  }
}

/// Bangun satu pohon widget berisi PanelProvider asli + satu
/// RefreshOnActivate yang mengawal [pageIndex], dibungkus tombol-tombol
/// buat memindahkan `currentPage` — jadi persis pola yang dipakai
/// PanelPage._buildCurrentPage, minus 8 halaman lain yang tidak relevan.
Widget _harness({
  required int pageIndex,
  required _FakePageProvider provider,
}) {
  return MaterialApp(
    home: ChangeNotifierProvider<PanelProvider>(
      create: (ctx) => PanelProvider(ctx),
      child: Builder(builder: (context) {
        final panelProv = context.watch<PanelProvider>();
        return Scaffold(
          body: Column(
            children: [
              for (int i = 0; i < 3; i++)
                ElevatedButton(
                  key: ValueKey('goto-$i'),
                  onPressed: () => panelProv.setPage(i),
                  child: Text('goto $i'),
                ),
              ChangeNotifierProvider<_FakePageProvider>.value(
                value: provider,
                child: RefreshOnActivate<_FakePageProvider>(
                  pageIndex: pageIndex,
                  refresh: (p) => p.refreshData(),
                  child: const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        );
      }),
    ),
  );
}

void main() {
  testWidgets(
      'tidak refresh pada kunjungan pertama (initState halaman sudah muat sendiri)',
      (tester) async {
    final provider = _FakePageProvider();
    await tester.pumpWidget(_harness(pageIndex: 0, provider: provider));
    await tester.pumpAndSettle();

    expect(provider.refreshCalls, 0);
  });

  testWidgets('refresh persis sekali tiap kali halaman dibuka ULANG',
      (tester) async {
    final provider = _FakePageProvider();
    // Mulai di halaman lain (bukan pageIndex 0) supaya "aktif pertama kali"
    // terjadi lewat tombol, bukan lewat state awal — mencocokkan urutan
    // nyata di aplikasi (user datang dari halaman lain).
    await tester.pumpWidget(_harness(pageIndex: 0, provider: provider));
    await tester.tap(find.byKey(const ValueKey('goto-1')));
    await tester.pumpAndSettle();
    expect(provider.refreshCalls, 0,
        reason: 'pindah ke halaman LAIN tidak boleh memicu refresh');

    await tester.tap(find.byKey(const ValueKey('goto-0')));
    await tester.pumpAndSettle();
    expect(provider.refreshCalls, 1,
        reason: 'kunjungan pertama ke halaman 0 sudah lewat di awal, '
            'jadi ini terhitung REAKTIVASI pertama -> harus refresh sekali');

    await tester.tap(find.byKey(const ValueKey('goto-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('goto-0')));
    await tester.pumpAndSettle();
    expect(provider.refreshCalls, 2,
        reason: 'reaktivasi kedua harus refresh lagi — bukti data tidak '
            'pernah beku selama halamannya dibuka ulang');

    // Berpindah ke halaman lain lalu balik lagi TANPA pernah pergi tidak
    // boleh nembak refresh ganda hanya karena rebuild biasa (mis. tombol
    // lain ditekan sementara currentPage tidak berubah).
    await tester.tap(find.byKey(const ValueKey('goto-2')));
    await tester.pumpAndSettle();
    expect(provider.refreshCalls, 2,
        reason: 'masih di halaman lain, jumlah refresh tidak boleh berubah');
  });
}
