import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:emr_homemade/domain/panel/panel_provider.dart';

/// Panggil ulang [refresh] tiap kali halaman [pageIndex] dibuka LAGI (bukan
/// pertama kali) — pasangan dari cache di `_PanelPageState._pageAt`
/// ([panel_page.dart]), yang membiarkan provider hidup terus supaya
/// pindah-balik antar halaman instan. Tanpa ini, data provider (mis.
/// dropdown pasien di "Buat Asesmen") beku di kondisi saat halaman pertama
/// dibuka — pasien baru dari halaman lain tidak pernah muncul.
///
/// Generik lewat `refreshData()`: semua provider halaman punya method itu
/// dengan nama & bentuk sama, jadi satu widget ini cukup untuk semuanya.
/// Publik supaya bisa dites via `test/refresh_on_activate_test.dart`.
class RefreshOnActivate<T extends ChangeNotifier> extends StatefulWidget {
  final int pageIndex;
  final Future<void> Function(T provider) refresh;
  final Widget child;

  const RefreshOnActivate({
    super.key,
    required this.pageIndex,
    required this.refresh,
    required this.child,
  });

  @override
  State<RefreshOnActivate<T>> createState() => _RefreshOnActivateState<T>();
}

class _RefreshOnActivateState<T extends ChangeNotifier>
    extends State<RefreshOnActivate<T>> {
  int? _previousPage;
  bool _sawFirstActivation = false;

  @override
  Widget build(BuildContext context) {
    final int currentPage = context.watch<PanelProvider>().currentPage;
    final bool active = currentPage == widget.pageIndex;
    final bool wasActive = _previousPage == widget.pageIndex;

    // Transisi TIDAK-aktif -> aktif. Lewat pertama kali dengan sengaja:
    // provider baru saja selesai memuat data sendiri lewat constructor
    // atau initState-nya; memanggil refreshData() lagi di situ juga cuma
    // menembak query yang sama dua kali berturut-turut.
    if (active && !wasActive) {
      if (_sawFirstActivation) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.refresh(context.read<T>());
        });
      }
      _sawFirstActivation = true;
    }
    _previousPage = currentPage;

    return widget.child;
  }
}
