import 'package:flutter/material.dart';
import 'package:emr_homemade/domain/asesmen_psikologis/create_asesmen_psikologis_provider.dart';
import 'package:emr_homemade/domain/asesmen_psikologis/manage_asesmen_psikologis_provider.dart';
import 'package:emr_homemade/domain/instrumen/instrumen_provider.dart';
import 'package:emr_homemade/domain/instrumen_item/instrumen_item_provider.dart';
import 'package:emr_homemade/domain/obat/obat_provider.dart';
import 'package:emr_homemade/domain/pasien/pasien_provider.dart';
import 'package:emr_homemade/domain/user/user_provider.dart';
import 'package:emr_homemade/presentation/home/home_page.dart';
import 'package:emr_homemade/presentation/obat/obat_page.dart';
import 'package:emr_homemade/presentation/report/dashboard.dart';
import 'package:emr_homemade/presentation/user/user_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:emr_homemade/domain/panel/panel_provider.dart';
import 'package:emr_homemade/presentation/panel/panel_button.dart';
import 'package:emr_homemade/presentation/panel/panel_footer.dart';
import 'package:emr_homemade/presentation/panel/refresh_on_activate.dart';
import 'package:emr_homemade/presentation/pasien/manage_pasien.dart';
import 'package:emr_homemade/presentation/instrumen/instrumen_page.dart';
import 'package:emr_homemade/presentation/instrumen/instrumen_item_page.dart';
import 'package:emr_homemade/presentation/asesmen/create_asesmen_psikologis_page.dart';
import 'package:emr_homemade/presentation/asesmen/manage_asesmen_psikologis_page.dart';
import 'package:emr_homemade/utils/widgets/constant.dart';

class PanelPage extends StatefulWidget {
  const PanelPage({super.key});

  @override
  State<PanelPage> createState() => _PanelPageState();
}

class _PanelPageState extends State<PanelPage> {
  /// Di bawah lebar ini, sidebar permanen diganti Drawer. Dihitung: 220
  /// lebar sidebar + 82 chrome konten = 302, ditambah ambang 640 tempat
  /// layout pindah ke mode kolom/kartu.
  static const double _sidebarBreakpoint = 942;

  /// Judul per halaman, memakai teks yang sama persis dengan label tombol
  /// di [_panelItems]. Hanya dipakai di mode sempit, tempat sidebar tidak
  /// lagi terlihat sehingga pengguna kehilangan penanda posisi.
  static const Map<int, String> _pageTitles = {
    0: 'Home',
    1: 'Dashboard',
    2: 'Data Pasien',
    3: 'Data Instrumen',
    4: 'Detail Instrumen',
    5: 'Buat Asesmen',
    6: 'Daftar Asesmen',
    7: 'Data Obat',
    8: 'Data User',
  };

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// Halaman yang sudah pernah dibuka tetap hidup di [IndexedStack] (cuma
  /// disembunyikan, bukan dibongkar) supaya pindah-balik antar menu tidak
  /// menarik ulang data dari server. Halaman yang belum pernah dibuka tetap
  /// placeholder kosong, supaya tidak semua provider dibuat sekaligus di awal.
  final Map<int, Widget> _pageCache = {};

  Widget _pageAt(int index, int currentPage) {
    if (index == currentPage || _pageCache.containsKey(index)) {
      return _pageCache.putIfAbsent(index, () => _buildCurrentPage(index));
    }
    return const SizedBox.shrink();
  }

  // Home (0) & Dashboard (1) bukan ChangeNotifierProvider seperti halaman
  // lain, jadi RefreshOnActivate (lewat Provider) tidak menjangkau —
  // dipakai GlobalKey buat panggil refresh() publik di State-nya langsung.
  final GlobalKey<HomePageState> _homeKey = GlobalKey<HomePageState>();
  final GlobalKey<DashboardPageState> _dashboardKey =
      GlobalKey<DashboardPageState>();
  final Set<int> _everActivated = {};
  int? _lastPage;

  /// Pasangan [RefreshOnActivate] khusus untuk halaman 0 dan 1. Dipanggil
  /// dari `build()` karena keduanya tidak duduk di dalam subtree yang
  /// dibungkus Provider seperti halaman lain.
  void _refreshHomeOrDashboardIfReactivated(int currentPage) {
    if (_lastPage == currentPage) return;
    final bool isRevisit = _everActivated.contains(currentPage);
    _everActivated.add(currentPage);
    _lastPage = currentPage;
    if (!isRevisit) return; // pertama kali dibuka: initState-nya sudah muat sendiri.

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (currentPage == 0) {
        _homeKey.currentState?.refresh();
      } else if (currentPage == 1) {
        _dashboardKey.currentState?.refresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PanelProvider(context),
      child: Consumer<PanelProvider>(
        builder: (context, prov, _) {
          _refreshHomeOrDashboardIfReactivated(prov.currentPage);

          final bool wide =
              MediaQuery.of(context).size.width >= _sidebarBreakpoint;

          final double outerPad = wide ? 16 : 8;
          final double innerPad = wide ? 25 : 12;

          return PopScope(
            // Halaman utama (0) dibiarkan pop seperti biasa: di sanalah Back
            // memang berarti "keluar aplikasi".
            canPop: prov.currentPage == 0,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) return;

              // Drawer terbuka lebih dulu ditutup, supaya Back tidak
              // melompati satu lapis UI yang sedang terlihat.
              final ScaffoldState? scaffold = _scaffoldKey.currentState;
              if (scaffold != null && scaffold.isDrawerOpen) {
                scaffold.closeDrawer();
                return;
              }

              prov.setPage(0);
            },
            child: Scaffold(
              key: _scaffoldKey,
              backgroundColor: Colors.grey[200],
              // Drawer hanya ADA di mode sempit. Kalau selalu dipasang,
              // Scaffold menampilkan tombol hamburger sendiri di desktop.
              drawer: wide ? null : _navDrawer(prov),
              body: Column(
                children: [
                  Expanded(
                    child: Container(
                      color: Colors.white,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (wide) _navbar(prov),
                          Flexible(
                            flex: 1,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: outerPad),
                              child: Column(
                                children: [
                                  if (!wide) _compactBar(prov),
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(25)),
                                      child: Container(
                                        color: whitePrimary,
                                        padding: EdgeInsets.all(innerPad),
                                        child: IndexedStack(
                                          index: prov.currentPage
                                              .clamp(0, _pageTitles.length - 1),
                                          children: [
                                            for (int i = 0;
                                                i < _pageTitles.length;
                                                i++)
                                              _pageAt(i, prov.currentPage),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const PanelFooter(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Baris tipis pengganti sidebar di mode sempit: tombol hamburger untuk
  /// membuka Drawer, plus nama halaman yang sedang aktif.
  Widget _compactBar(PanelProvider prov) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.menu),
          color: blueDark,
          tooltip: 'Buka menu',
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        Expanded(
          child: Text(
            _pageTitles[prov.currentPage] ?? 'Home',
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Navigasi yang sama persis dengan sidebar — [_panelItems] yang itu juga,
  /// bukan daftar yang disusun ulang — hanya dipindah ke dalam Drawer.
  Widget _navDrawer(PanelProvider prov) {
    return Drawer(
      width: 260,
      child: SafeArea(
        child: Column(
          children: [
            PanelHeader(
              // Di Drawer tidak ada gunanya menciutkan navigasi, jadi header
              // yang di sidebar berfungsi sebagai tombol minimize di sini
              // dipakai untuk menutup Drawer.
              minimalState: false,
              onTap: () => _scaffoldKey.currentState?.closeDrawer(),
            ),
            _panelItems(
              prov,
              minimal: false,
              onPageSelected: () => _scaffoldKey.currentState?.closeDrawer(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentPage(int currentPage) {
    switch (currentPage) {
      case 0:
        return HomePage(key: _homeKey);
      case 1:
        return DashboardPage(key: _dashboardKey);
      case 2:
        return ChangeNotifierProvider(
          create: (context) => PasienProvider(context),
          child: RefreshOnActivate<PasienProvider>(
            pageIndex: 2,
            refresh: (p) => p.refreshData(),
            child: const ManagePasienPage(key: ValueKey('manage_pasien')),
          ),
        );
      case 3:
        return ChangeNotifierProvider(
          create: (context) => InstrumenProvider(context),
          child: RefreshOnActivate<InstrumenProvider>(
            pageIndex: 3,
            refresh: (p) => p.refreshData(),
            child: const InstrumenPage(key: ValueKey('instrumen_page')),
          ),
        );
      case 4:
        return ChangeNotifierProvider(
          create: (context) => InstrumenItemProvider(context),
          child: RefreshOnActivate<InstrumenItemProvider>(
            pageIndex: 4,
            refresh: (p) => p.refreshData(),
            child:
                const InstrumenItemPage(key: ValueKey('instrumen_item_page')),
          ),
        );
      case 5:
        return ChangeNotifierProvider(
          create: (context) => CreateAsesmenPsikologisProvider(context),
          child: RefreshOnActivate<CreateAsesmenPsikologisProvider>(
            pageIndex: 5,
            refresh: (p) => p.refreshData(),
            child: const CreateAsesmenPsikologisPage(
                key: ValueKey('create_asesmen')),
          ),
        );
      case 6:
        return ChangeNotifierProvider(
          create: (context) => ManageAsesmenPsikologisProvider(context),
          child: RefreshOnActivate<ManageAsesmenPsikologisProvider>(
            pageIndex: 6,
            refresh: (p) => p.refreshData(),
            child: const ManageAsesmenPsikologisPage(
                key: ValueKey('manage_asesmen')),
          ),
        );
      case 7:
        return ChangeNotifierProvider(
          create: (context) => ObatProvider(context),
          child: RefreshOnActivate<ObatProvider>(
            pageIndex: 7,
            refresh: (p) => p.refreshData(),
            child: const DrugManagementPage(key: ValueKey('obat_page')),
          ),
        );
      case 8:
        return ChangeNotifierProvider(
          create: (context) => UserProvider(context),
          child: RefreshOnActivate<UserProvider>(
            pageIndex: 8,
            refresh: (p) => p.refreshData(),
            child: const UserManagementPage(key: ValueKey('user_page')),
          ),
        );
      default:
        return const HomePage(key: ValueKey('default_page'));
    }
  }

  Widget _navbar(PanelProvider prov) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topRight: Radius.circular(25),
        bottomRight: Radius.circular(25),
      ),
      child: Container(
        padding: const EdgeInsets.only(right: 2),
        width: prov.minimizeNav ? 50 : 220,
        decoration: const BoxDecoration(
          color: whitePrimary,
          border: Border(
            right: BorderSide(color: Colors.white),
          ),
        ),
        child: Column(
          children: [
            PanelHeader(
              minimalState: prov.minimizeNav,
              onTap: () => setState(() => prov.minimizeNav = !prov.minimizeNav),
            ),
            _panelItems(prov, minimal: prov.minimizeNav),
          ],
        ),
      ),
    );
  }

  /// Daftar navigasi tunggal, dipakai sidebar maupun Drawer. [minimal]
  /// dipisah dari `prov.minimizeNav` supaya Drawer selalu berlabel penuh.
  /// [onPageSelected] dipanggil HANYA setelah perpindahan halaman, bukan
  /// buka/tutup accordion.
  Widget _panelItems(
    PanelProvider prov, {
    required bool minimal,
    VoidCallback? onPageSelected,
  }) {
    void selectPage(int index) {
      prov.setPage(index);
      onPageSelected?.call();
    }

    return Expanded(
      child: ListView(
        children: [
          if (!minimal)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Home and Dashboard",
                style: GoogleFonts.nunito(fontSize: 14),
              ),
            ),
          PanelButton(
            onTap: () => selectPage(0),
            activeState: prov.currentPage == 0,
            minimalState: minimal,
            icon: Icons.dashboard,
            text: 'Home',
            alignment: TextAlign.start,
          ),
          PanelButton(
            onTap: () => selectPage(1),
            activeState: prov.currentPage == 1,
            minimalState: minimal,
            icon: Icons.bar_chart,
            text: 'Dashboard',
            alignment: TextAlign.start,
          ),
          if (!minimal)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Text(
                "Data",
                style: GoogleFonts.nunito(fontSize: 14),
              ),
            ),
          PanelButton(
            onTap: () => selectPage(2),
            activeState: prov.currentPage == 2,
            minimalState: minimal,
            icon: Icons.manage_accounts,
            text: 'Data Pasien',
            alignment: TextAlign.start,
          ),
          PanelButton(
            onTap: () => prov.setAccordionType(1),
            activeState: prov.isOpenAccordion[1],
            minimalState: minimal,
            icon: Icons.library_books,
            text: 'Data Instrumen',
            isAccordionHeader: true,
            alignment: TextAlign.start,
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: prov.isOpenAccordion[1]
                ? Column(
                    children: [
                      PanelButton(
                        onTap: () => selectPage(3),
                        activeState: prov.currentPage == 3,
                        minimalState: minimal,
                        isItem: true,
                        icon: Icons.book,
                        text: 'Data Instrumen',
                        alignment: TextAlign.start,
                      ),
                      PanelButton(
                        onTap: () => selectPage(4),
                        activeState: prov.currentPage == 4,
                        minimalState: minimal,
                        isItem: true,
                        icon: Icons.list_alt,
                        text: 'Detail Instrumen',
                        alignment: TextAlign.start,
                      ),
                    ],
                  )
                : const SizedBox(),
          ),
          PanelButton(
            onTap: () => prov.setAccordionType(2),
            activeState: prov.isOpenAccordion[2],
            minimalState: minimal,
            icon: Icons.psychology,
            text: 'Data Asesmen',
            isAccordionHeader: true,
            alignment: TextAlign.start,
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: prov.isOpenAccordion[2]
                ? Column(
                    children: [
                      PanelButton(
                        onTap: () => selectPage(5),
                        activeState: prov.currentPage == 5,
                        minimalState: minimal,
                        isItem: true,
                        icon: Icons.psychology_alt,
                        text: 'Buat Asesmen',
                        alignment: TextAlign.start,
                      ),
                      PanelButton(
                        onTap: () => selectPage(6),
                        activeState: prov.currentPage == 6,
                        minimalState: minimal,
                        isItem: true,
                        icon: Icons.fact_check,
                        text: 'Daftar Asesmen',
                        alignment: TextAlign.start,
                      ),
                    ],
                  )
                : const SizedBox(),
          ),
          PanelButton(
            onTap: () => selectPage(7),
            activeState: prov.currentPage == 7,
            minimalState: minimal,
            icon: Icons.medical_services,
            text: 'Data Obat',
            alignment: TextAlign.start,
          ),
          PanelButton(
            onTap: () => selectPage(8),
            activeState: prov.currentPage == 8,
            minimalState: minimal,
            icon: Icons.people,
            text: 'Data User',
            alignment: TextAlign.start,
          ),
        ],
      ),
    );
  }
}
