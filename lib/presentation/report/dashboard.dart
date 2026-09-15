import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:emr_homemade/FBBlock/sk_block.dart';
import 'package:emr_homemade/utils/widgets/constant.dart';
import 'package:emr_homemade/data/repositories/pasien_repo.dart';
import 'package:emr_homemade/data/repositories/kunjungan_repo.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => DashboardPageState();
}

// Publik (bukan _DashboardPageState) dan punya method refresh() publik:
// dipakai PanelPage lewat GlobalKey supaya statistik dashboard bisa ditarik
// ulang saat halaman ini dibuka lagi, bukan cuma sekali waktu pertama dibuka.
class DashboardPageState extends State<DashboardPage> {
  bool _isLoading = true;
  bool _localeInitialized = false;
  
  int _totalPasien = 0;
  int _pasienLakiLaki = 0;
  int _pasienPerempuan = 0;
  int _kunjunganHariIni = 0;
  int _kunjunganMingguIni = 0;
  int _kunjunganBulanIni = 0;
  int _kunjunganTahunIni = 0;
  
  Map<String, int> _kunjunganPerBulan = {};
  Map<String, int> _distribusiUsia = {};
  Map<String, int> _diagnosisTop5 = {};

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
    } catch (e) {
      debugPrint("Error initializing locale: $e");
      _localeInitialized = true;
    }
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      final now = DateTime.now();
      
      final pasienList = await PasienRepo.getAll();
      _totalPasien = pasienList.length;
      _pasienLakiLaki = pasienList.where((p) => p.patientGender == 'L').length;
      _pasienPerempuan = pasienList.where((p) => p.patientGender == 'P').length;
      
      _distribusiUsia = {
        '0-17 tahun': 0,
        '18-30 tahun': 0,
        '31-45 tahun': 0,
        '46-60 tahun': 0,
        '60+ tahun': 0,
      };
      
      for (var pasien in pasienList) {
        final age = _calculateAge(pasien.patientBirthdate);
        if (age <= 17) {
          _distribusiUsia['0-17 tahun'] = (_distribusiUsia['0-17 tahun'] ?? 0) + 1;
        } else if (age <= 30) {
          _distribusiUsia['18-30 tahun'] = (_distribusiUsia['18-30 tahun'] ?? 0) + 1;
        } else if (age <= 45) {
          _distribusiUsia['31-45 tahun'] = (_distribusiUsia['31-45 tahun'] ?? 0) + 1;
        } else if (age <= 60) {
          _distribusiUsia['46-60 tahun'] = (_distribusiUsia['46-60 tahun'] ?? 0) + 1;
        } else {
          _distribusiUsia['60+ tahun'] = (_distribusiUsia['60+ tahun'] ?? 0) + 1;
        }
      }
      
      final allKunjungan = await KunjunganRepo.getAll(limit: 5000);
      
      final today = DateTime(now.year, now.month, now.day);
      final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
      final startOfMonth = DateTime(now.year, now.month, 1);
      final startOfYear = DateTime(now.year, 1, 1);
      
      _kunjunganHariIni = allKunjungan.where((k) {
        return k.tanggalKunjungan.isAfter(today.subtract(const Duration(days: 1)));
      }).length;
      
      _kunjunganMingguIni = allKunjungan.where((k) {
        return k.tanggalKunjungan.isAfter(startOfWeek.subtract(const Duration(days: 1)));
      }).length;
      
      _kunjunganBulanIni = allKunjungan.where((k) {
        return k.tanggalKunjungan.isAfter(startOfMonth.subtract(const Duration(days: 1)));
      }).length;
      
      _kunjunganTahunIni = allKunjungan.where((k) {
        return k.tanggalKunjungan.isAfter(startOfYear.subtract(const Duration(days: 1)));
      }).length;
      
      _kunjunganPerBulan = {};
      for (int i = 5; i >= 0; i--) {
        final month = DateTime(now.year, now.month - i, 1);
        final monthName = _formatMonthYear(month);
        final nextMonth = DateTime(month.year, month.month + 1, 1);
        
        final count = allKunjungan.where((k) {
          return k.tanggalKunjungan.isAfter(month.subtract(const Duration(days: 1))) &&
                 k.tanggalKunjungan.isBefore(nextMonth);
        }).length;
        
        _kunjunganPerBulan[monthName] = count;
      }
      
      final diagnosisCount = <String, int>{};
      for (var kunjungan in allKunjungan) {
        if (kunjungan.diagnosis.isNotEmpty) {
          diagnosisCount[kunjungan.diagnosis] = 
              (diagnosisCount[kunjungan.diagnosis] ?? 0) + 1;
        }
      }
      
      final sortedDiagnosis = diagnosisCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      _diagnosisTop5 = Map.fromEntries(sortedDiagnosis.take(5));
      
    } catch (e) {
      debugPrint("Error loading dashboard data: $e");
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  String _formatMonthYear(DateTime date) {
    try {
      if (_localeInitialized) {
        return DateFormat('MMM yyyy', 'id_ID').format(date);
      }
    } catch (e) {
      debugPrint("Error formatting month: $e");
    }
    return DateFormat('MMM yyyy').format(date);
  }

  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      color: bluePrimary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkBlock.pageHero(
              icon: Icons.bar_chart_rounded,
              // Emoji dilepas dari judul: di lencana ikon sudah ada grafik,
              // dan emoji-nya dirender sebagai gambar sehingga tidak ikut
              // mengecil bersama teks.
              title: 'Dashboard Analitik',
              subtitle:
                  'Pantau kinerja dan statistik sistem EMR secara real-time',
              footnote:
                  'Terakhir diperbarui: ${DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(DateTime.now())}',
              gradientColors: const [blueDeep, blueDark, bluePrimary],
            ),

            const SizedBox(height: 24),
            
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(60),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(bluePrimary),
                    strokeWidth: 3,
                  ),
                ),
              )
            else ...[
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _EnterpriseStatCard(
                    icon: Icons.people_rounded,
                    title: 'Total Pasien',
                    value: '$_totalPasien',
                    subtitle: 'Pasien terdaftar',
                    color: bluePrimary,
                    trend: '+${_pasienLakiLaki + _pasienPerempuan}',
                    trendPositive: true,
                  ),
                  _EnterpriseStatCard(
                    icon: Icons.today_rounded,
                    title: 'Kunjungan Hari Ini',
                    value: '$_kunjunganHariIni',
                    subtitle: DateFormat('dd MMM yyyy').format(DateTime.now()),
                    color: greenSuccess,
                    trendPositive: true,
                  ),
                  _EnterpriseStatCard(
                    icon: Icons.date_range_rounded,
                    title: 'Kunjungan Minggu Ini',
                    value: '$_kunjunganMingguIni',
                    subtitle: 'Minggu berjalan',
                    color: orangeWarning,
                    trendPositive: true,
                  ),
                  _EnterpriseStatCard(
                    icon: Icons.event_note_rounded,
                    title: 'Kunjungan Bulan Ini',
                    value: '$_kunjunganBulanIni',
                    subtitle: DateFormat('MMMM yyyy').format(DateTime.now()),
                    color: const Color(0xFF8B5CF6),
                    trendPositive: true,
                  ),
                ],
              ),
              
              const SizedBox(height: 40),
              
              // lineWrap: 2 kolom berdampingan overflow di HP (ruang per
              // kolom lebih kecil dari padding kartu di dalamnya); menumpuk
              // jadi 1 kolom di bawah 640dp.
              SkBlock.lineWrap(
                responsive: true,
                spacing: 24,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('Distribusi Gender Pasien', Icons.wc_rounded),
                      const SizedBox(height: 16),
                      _buildGenderDistribution(),

                      const SizedBox(height: 32),

                      _buildSectionHeader('Distribusi Usia Pasien', Icons.cake_rounded),
                      const SizedBox(height: 16),
                      _buildAgeDistribution(),
                    ],
                  ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('Trend Kunjungan', Icons.trending_up_rounded),
                      const SizedBox(height: 16),
                      _buildMonthlyVisits(),

                      const SizedBox(height: 32),

                      _buildSectionHeader('Top 5 Diagnosis', Icons.medical_information_rounded),
                      const SizedBox(height: 16),
                      _buildTopDiagnosis(),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _buildSummaryBanner(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return SkBlock.sectionHeader(
      title: title,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bluePrimary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: bluePrimary, size: 20),
      ),
      titleStyle: GoogleFonts.nunito(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: blackPrimary,
      ),
    );
  }

  Widget _buildGenderDistribution() {
    final total = _pasienLakiLaki + _pasienPerempuan;
    final malePercent = total > 0 ? (_pasienLakiLaki / total * 100).toStringAsFixed(1) : '0';
    final femalePercent = total > 0 ? (_pasienPerempuan / total * 100).toStringAsFixed(1) : '0';
    
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: whiteCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: greyBorder),
        boxShadow: [
          BoxShadow(
            color: bluePrimary.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _GenderCard(
                  icon: Icons.male_rounded,
                  label: 'Laki-laki',
                  count: _pasienLakiLaki,
                  percentage: '$malePercent%',
                  color: bluePrimary,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _GenderCard(
                  icon: Icons.female_rounded,
                  label: 'Perempuan',
                  count: _pasienPerempuan,
                  percentage: '$femalePercent%',
                  color: const Color(0xFFEC4899),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Row(
              children: [
                if (_pasienLakiLaki > 0)
                  Expanded(
                    flex: _pasienLakiLaki,
                    child: Container(
                      height: 14,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [bluePrimary, blueHighlight],
                        ),
                      ),
                    ),
                  ),
                if (_pasienPerempuan > 0)
                  Expanded(
                    flex: _pasienPerempuan,
                    child: Container(
                      height: 14,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFEC4899), Color(0xFFF472B6)],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgeDistribution() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: whiteCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: greyBorder),
        boxShadow: [
          BoxShadow(
            color: bluePrimary.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: _distribusiUsia.entries.map((entry) {
          final maxValue = _distribusiUsia.values.isEmpty ? 1 : 
              _distribusiUsia.values.reduce((a, b) => a > b ? a : b);
          final percent = maxValue > 0 ? (entry.value / maxValue) : 0.0;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkBlock.sectionHeader(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  title: entry.key,
                  titleStyle: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: blackPrimary,
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: bluePrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${entry.value}',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: bluePrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: percent,
                    backgroundColor: greyBackground,
                    valueColor: const AlwaysStoppedAnimation<Color>(bluePrimary),
                    minHeight: 10,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMonthlyVisits() {
    final maxValue = _kunjunganPerBulan.values.isEmpty
        ? 1
        : _kunjunganPerBulan.values.reduce((a, b) => a > b ? a : b);
    
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: whiteCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: greyBorder),
        boxShadow: [
          BoxShadow(
            color: bluePrimary.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: _kunjunganPerBulan.entries.map((entry) {
              final height = maxValue > 0 ? (entry.value / maxValue * 160) : 0.0;
              
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: bluePrimary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${entry.value}',
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: bluePrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: height < 30 ? 30 : height,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [blueDeep, bluePrimary, blueHighlight],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: bluePrimary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        entry.key.split(' ')[0],
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: greyText,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopDiagnosis() {
    if (_diagnosisTop5.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: whiteCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: greyBorder),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.inbox_rounded, size: 48, color: greyText.withValues(alpha: 0.5)),
              const SizedBox(height: 12),
              Text(
                'Belum ada data diagnosis',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: greyText,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    final colors = [
      redError,
      orangeWarning,
      const Color(0xFFF59E0B),
      greenSuccess,
      bluePrimary,
    ];
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: whiteCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: greyBorder),
        boxShadow: [
          BoxShadow(
            color: bluePrimary.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: _diagnosisTop5.entries.toList().asMap().entries.map((mapEntry) {
          final index = mapEntry.key;
          final entry = mapEntry.value;
          final color = colors[index % colors.length];
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withValues(alpha: 0.7)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      entry.key,
                      style: GoogleFonts.nunito(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: blackPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '${entry.value}',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSummaryBanner() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [blueDeep, blueDark, bluePrimary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: bluePrimary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(builder: (context, constraints) {
            final bool compact = constraints.maxWidth.isFinite &&
                constraints.maxWidth < SkBlock.compactBreakpoint;

            final metrics = <List<Object>>[
              [
                Icons.event_available_rounded,
                'Total Kunjungan',
                '$_kunjunganTahunIni'
              ],
              [
                Icons.trending_up_rounded,
                'Rata-rata per Bulan',
                (_kunjunganTahunIni / 12).toStringAsFixed(0)
              ],
              [Icons.groups_rounded, 'Pasien Aktif', '$_totalPasien'],
            ];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkBlock.sectionHeader(
                  title: 'Ringkasan Tahun ${DateTime.now().year}',
                  leadingSpacing: compact ? 12 : 16,
                  leading: Container(
                    padding: EdgeInsets.all(compact ? 10 : 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.analytics_rounded,
                      color: Colors.white,
                      size: compact ? 24 : 32,
                    ),
                  ),
                  titleStyle: GoogleFonts.nunito(
                    fontSize: compact ? 20 : 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: compact ? 18 : 28),

                if (compact)
                  Column(
                    children: [
                      for (var i = 0; i < metrics.length; i++) ...[
                        if (i != 0)
                          Divider(
                            height: 20,
                            thickness: 1,
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        Row(
                          children: [
                            Icon(metrics[i][0] as IconData,
                                color: Colors.white, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                metrics[i][1] as String,
                                style: GoogleFonts.nunito(
                                  fontSize: 16,
                                  color: Colors.white.withValues(alpha: 0.95),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              metrics[i][2] as String,
                              style: GoogleFonts.nunito(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  )
                else
                  Row(
                    children: [
                      for (var i = 0; i < metrics.length; i++) ...[
                        if (i != 0)
                          Container(
                            width: 2,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        Expanded(
                          child: _SummaryMetric(
                            icon: metrics[i][0] as IconData,
                            label: metrics[i][1] as String,
                            value: metrics[i][2] as String,
                          ),
                        ),
                      ],
                    ],
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _EnterpriseStatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final String? trend;
  final bool trendPositive;

  const _EnterpriseStatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    this.trend,
    this.trendPositive = true,
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
        border: Border.all(color: greyBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
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
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const Spacer(),
              if (trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: trendPositive
                        ? greenSuccess.withValues(alpha: 0.1)
                        : redError.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        trendPositive
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        size: 14,
                        color: trendPositive ? greenSuccess : redError,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        trend!,
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          color: trendPositive ? greenSuccess : redError,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: greyText,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.nunito(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: blackPrimary,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
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

class _GenderCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final String percentage;
  final Color color;

  const _GenderCard({
    required this.icon,
    required this.label,
    required this.count,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withValues(alpha: 0.7)],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 36),
        ),
        const SizedBox(height: 14),
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 15,
            color: greyText,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$count',
          style: GoogleFonts.nunito(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: blackPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            percentage,
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white.withValues(alpha: 0.9),
          size: 28,
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: GoogleFonts.nunito(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.9),
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}