import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:emr_homemade/FBBlock/sk_block.dart';
import 'package:emr_homemade/utils/widgets/constant.dart';
import 'package:provider/provider.dart';
import 'package:emr_homemade/domain/panel/panel_provider.dart';
import 'package:emr_homemade/data/repositories/pasien_repo.dart';
import 'package:emr_homemade/data/repositories/kunjungan_repo.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

// Publik (bukan _HomePageState) dan punya method refresh() publik: dipakai
// PanelPage lewat GlobalKey supaya statistik di kartu ini bisa ditarik ulang
// saat halaman ini dibuka lagi (bukan cuma sekali waktu pertama dibuka) —
// tanpa ini, "Total Pasien" dkk beku di angka lama selama sesi masih
// berjalan walau ada pasien baru ditambahkan di halaman lain.
class HomePageState extends State<HomePage> {
  int _totalPasien = 0;
  int _kunjunganHariIni = 0;
  int _kunjunganBulanIni = 0;
  bool _isLoading = true;
  bool _localeInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeLocale();
  }

  /// Dipanggil PanelPage lewat GlobalKey tiap kali halaman ini dibuka lagi.
  Future<void> refresh() => _loadDashboardData();

  Future<void> _initializeLocale() async {
    try {
      await initializeDateFormatting('id_ID', null);
      _localeInitialized = true;
      _loadDashboardData();
    } catch (e) {
      debugPrint("Error initializing locale: $e");
      _localeInitialized = true;
      _loadDashboardData();
    }
  }

  Future<void> _loadDashboardData() async {
    if (!_localeInitialized) return;

    setState(() => _isLoading = true);

    try {
      final pasienList = await PasienRepo.getAll();
      _totalPasien = pasienList.length;

      final allKunjungan = await KunjunganRepo.getAll(limit: 1000);
      final today = DateTime.now();
      final startOfMonth = DateTime(today.year, today.month, 1);

      _kunjunganHariIni = allKunjungan.where((k) {
        return k.tanggalKunjungan.year == today.year &&
            k.tanggalKunjungan.month == today.month &&
            k.tanggalKunjungan.day == today.day;
      }).length;

      _kunjunganBulanIni = allKunjungan.where((k) {
        return k.tanggalKunjungan
            .isAfter(startOfMonth.subtract(const Duration(days: 1)));
      }).length;
    } catch (e) {
      debugPrint("Error loading dashboard data: $e");
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  String _getFormattedDate() {
    try {
      if (_localeInitialized) {
        return DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(DateTime.now());
      }
    } catch (e) {
      debugPrint("Error formatting date: $e");
    }
    return DateFormat('dd/MM/yyyy').format(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<PanelProvider>(context, listen: false);

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkBlock.pageHero(
              icon: Icons.medical_services_rounded,
              title: 'Selamat Datang!',
              subtitle: 'Sistem Manajemen Rekam Medis Elektronik Psikiatri',
              footnote: _getFormattedDate(),
              gradientColors: const [blueDeep, blueDark, bluePrimary],
            ),

            const SizedBox(height: 24),

            if (_isLoading)
              const Center(child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(bluePrimary),
              ))
            else
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _StatisticCard(
                    icon: Icons.people_rounded,
                    title: 'Total Pasien',
                    value: '$_totalPasien',
                    color: bluePrimary,
                    subtitle: 'Pasien Terdaftar',
                  ),
                  _StatisticCard(
                    icon: Icons.calendar_today_rounded,
                    title: 'Kunjungan Hari Ini',
                    value: '$_kunjunganHariIni',
                    color: greenSuccess,
                    subtitle: DateFormat('dd MMM yyyy').format(DateTime.now()),
                  ),
                  _StatisticCard(
                    icon: Icons.trending_up_rounded,
                    title: 'Kunjungan Bulan Ini',
                    value: '$_kunjunganBulanIni',
                    color: orangeWarning,
                    subtitle: DateFormat('MMMM yyyy').format(DateTime.now()),
                  ),
                ],
              ),

            const SizedBox(height: 40),

            Row(
              children: [
                Container(
                  width: 4,
                  height: 32,
                  decoration: BoxDecoration(
                    color: bluePrimary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Akses Cepat',
                  style: GoogleFonts.nunito(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: blackPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // LayoutBuilder mengukur lebar total sekali, tiap kartu dibungkus
            // SizedBox setengah lebar di HP — hasilnya grid 2 kolom tanpa
            // ubah logic compact milik _QuickActionCard sendiri.
            LayoutBuilder(builder: (context, constraints) {
              final bool phone = constraints.maxWidth < SkBlock.compactBreakpoint;
              final double? colWidth =
                  phone ? (constraints.maxWidth - 16) / 2 : null;

              final List<Widget> cards = [
                _QuickActionCard(
                  icon: Icons.bar_chart_rounded,
                  title: 'Laporan',
                  description: 'Lihat Dashboard & statistik',
                  color: const Color(0xFF6366F1),
                  onTap: () => prov.setPage(1),
                ),
                _QuickActionCard(
                  icon: Icons.people_rounded,
                  title: 'Data Pasien',
                  description: 'Lihat & kelola data pasien',
                  color: greenSuccess,
                  onTap: () => prov.setPage(2),
                ),
                _QuickActionCard(
                  icon: Icons.psychology_alt_rounded,
                  title: 'Buat Asesmen',
                  description: 'Buat asesmen psikologis baru',
                  color: const Color(0xFF8B5CF6),
                  onTap: () => prov.setPage(5),
                ),
                _QuickActionCard(
                  icon: Icons.fact_check_rounded,
                  title: 'Daftar Asesmen',
                  description: 'Lihat riwayat asesmen',
                  color: orangeWarning,
                  onTap: () => prov.setPage(6),
                ),
                _QuickActionCard(
                  icon: Icons.book_rounded,
                  title: 'Data Instrumen',
                  description: 'Kelola instrumen asesmen',
                  color: const Color(0xFF14B8A6),
                  onTap: () => prov.setPage(3),
                ),
                _QuickActionCard(
                  icon: Icons.list_alt_rounded,
                  title: 'Detail Instrumen',
                  description: 'Kelola item instrumen',
                  color: const Color(0xFF06B6D4),
                  onTap: () => prov.setPage(4),
                ),
                _QuickActionCard(
                  icon: Icons.medication_rounded,
                  title: 'Data Obat',
                  description: 'Kelola data obat',
                  color: redError,
                  onTap: () => prov.setPage(7),
                ),
              ];

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: colWidth == null
                    ? cards
                    : cards
                        .map((c) => SizedBox(width: colWidth, child: c))
                        .toList(),
              );
            }),

            const SizedBox(height: 40),

            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: blueLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: blueSec.withValues(alpha: 0.5), width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: bluePrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.info_rounded,
                      color: bluePrimary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sistem EMR Psikiatri',
                          style: GoogleFonts.nunito(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: blackPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Platform terintegrasi untuk manajemen rekam medis, asesmen psikologis, dan monitoring pasien psikiatri dengan fitur lengkap dan user-friendly.',
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            color: greyText,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatisticCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  const _StatisticCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final bool compact = constraints.maxWidth.isFinite &&
          constraints.maxWidth < SkBlock.compactBreakpoint;
      return Container(
      width: compact ? constraints.maxWidth : 280,
      padding: EdgeInsets.all(compact ? 18 : 24),
      decoration: BoxDecoration(
        color: whiteCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: greyBorder),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const Spacer(),
              const Icon(Icons.arrow_upward_rounded,
                  color: greenSuccess, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: greyText,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.nunito(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: blackPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.nunito(
              fontSize: 13,
              color: greyText.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
      );
    });
  }
}

class _QuickActionCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final bool compact = constraints.maxWidth.isFinite &&
          constraints.maxWidth < SkBlock.compactBreakpoint;
      return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, _isHovered ? -8 : 0, 0),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: compact ? constraints.maxWidth : 280,
            padding: EdgeInsets.all(compact ? 18 : 24),
            decoration: BoxDecoration(
              color: _isHovered ? greyBackground : whiteCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isHovered
                    ? widget.color.withValues(alpha: 0.4)
                    : greyBorder,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: _isHovered ? 0.15 : 0.05),
                  blurRadius: _isHovered ? 20 : 8,
                  offset: Offset(0, _isHovered ? 8 : 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    widget.icon,
                    color: widget.color,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  widget.title,
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: blackPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.description,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: greyText,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'Akses',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: widget.color,
                      ),
                    ),
                    const SizedBox(width: 6),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      transform: Matrix4.translationValues(
                        _isHovered ? 4 : 0,
                        0,
                        0,
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: widget.color,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      );
    });
  }
}