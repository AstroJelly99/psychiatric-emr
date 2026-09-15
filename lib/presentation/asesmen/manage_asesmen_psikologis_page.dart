import 'package:flutter/material.dart';
import 'package:emr_homemade/FBBlock/sk_block.dart';
import 'package:emr_homemade/data/models/asesmen_psikologis_model.dart';
import 'package:emr_homemade/data/models/instrumen_item_model.dart';
import 'package:emr_homemade/data/models/item_asesmen_psikologis_model.dart';
import 'package:emr_homemade/domain/asesmen_psikologis/manage_asesmen_psikologis_provider.dart';
import 'package:emr_homemade/utils/widgets/alert_dialogs.dart';
import 'package:emr_homemade/utils/widgets/constant.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ChartData {
  final String label;
  final double value;

  ChartData(this.label, this.value);
}

class DistributionData {
  final String category;
  final int count;
  final Color color;

  DistributionData(this.category, this.count, this.color);
}

class ManageAsesmenPsikologisPage extends StatefulWidget {
  const ManageAsesmenPsikologisPage({super.key});

  @override
  State<ManageAsesmenPsikologisPage> createState() =>
      _ManageAsesmenPsikologisPageState();
}

class _ManageAsesmenPsikologisPageState
    extends State<ManageAsesmenPsikologisPage> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  void _refreshData() {
    final prov = context.read<ManageAsesmenPsikologisProvider>();
    prov.refreshData();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ManageAsesmenPsikologisProvider>(
      builder: (context, prov, _) {
        return Scaffold(
          backgroundColor: Colors.grey[50],
          body: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                // Header ini di luar area scroll, tingginya dibayar terus —
                // di HP dipadatkan (bukan ditumpuk): subjudul dilepas, judul
                // mengecil, kartu statistik jadi varian ringkas sebaris.
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final bool compact = constraints.maxWidth.isFinite &&
                        constraints.maxWidth < SkBlock.compactBreakpoint;

                    if (compact) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SkBlock.sectionHeader(
                              leading: const Icon(
                                Icons.psychology,
                                color: blueHighlight,
                                size: 22,
                              ),
                              leadingSpacing: 8,
                              title: "Kelola Asesmen Psikologis",
                              titleStyle: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard(
                                    "Total Asesmen",
                                    prov.filteredAsesmenList.length.toString(),
                                    Icons.assessment,
                                    Colors.blue,
                                    compact: true,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildStatCard(
                                    "Rata-rata Skor",
                                    prov.getAverageScore(),
                                    Icons.trending_up,
                                    Colors.green,
                                    compact: true,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.all(20),
                      child: SkBlock.overflowWrap(
                        spacing: 16,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SkBlock.sectionHeader(
                            leading: const Icon(
                              Icons.psychology,
                              color: blueHighlight,
                              size: 32,
                            ),
                            title: "Kelola Asesmen Psikologis",
                            titleStyle: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            subtitle: "Manage Psychological Assessments",
                            subtitleStyle: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          SkBlock.overflowWrap(
                            spacing: 16,
                            children: [
                              _buildStatCard(
                                "Total Asesmen",
                                prov.filteredAsesmenList.length.toString(),
                                Icons.assessment,
                                Colors.blue,
                              ),
                              _buildStatCard(
                                "Rata-rata Skor",
                                prov.getAverageScore(),
                                Icons.trending_up,
                                Colors.green,
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 1400),
                      child: Column(
                        children: [
                          _buildFilterSection(context, prov),
                          const SizedBox(height: 20),
                          if (prov.filteredAsesmenList.isNotEmpty) ...[
                            _buildChartsSection(context, prov),
                            const SizedBox(height: 20),
                          ],
                          _buildListSection(context, prov),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// [compact] dipakai hanya oleh header versi HP. Isinya sama — ikon, angka,
  /// label — tapi dipadatkan supaya dua kartu tetap muat sebaris di 360dp
  /// alih-alih menumpuk dan memakan tinggi dua kali lipat.
  Widget _buildStatCard(
      String label, String value, IconData icon, Color color,
      {bool compact = false}) {
    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(
      BuildContext context, ManageAsesmenPsikologisProvider prov) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: blueHighlight.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: SkBlock.sectionHeader(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              leading: const Icon(Icons.filter_list, color: blueHighlight),
              title: "Filter Data",
              titleStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: blueHighlight,
              ),
              trailing: prov.hasActiveFilters()
                  ? TextButton.icon(
                      onPressed: prov.resetFilters,
                      icon: const Icon(Icons.clear, size: 18),
                      label: const Text("Clear All"),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    )
                  : null,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Column(
              children: [
                SkBlock.lineWrap(
                  responsive: true,
                  spacing: 16,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildEnhancedDropdown(
                        context: context,
                        label: "Filter Pasien",
                        icon: Icons.person,
                        value: prov.selectedPasienFilter,
                        allItems: prov.pasienList,
                        displayText: (pasien) => pasien.patientName,
                        itemValue: (pasien) => pasien.pasienId,
                        searchFilter: (pasien, query) =>
                            pasien.patientName.toLowerCase().contains(query.toLowerCase()) ||
                            pasien.patientPhone.contains(query),
                        onChanged: (value) {
                          prov.selectedPasienFilter = value;
                          prov.applyFilters();
                        },
                        hint: "Cari berdasarkan nama...",
                      ),
                    _buildEnhancedDropdown(
                        context: context,
                        label: "Filter Instrumen",
                        icon: Icons.assessment,
                        value: prov.selectedInstrumenFilter,
                        allItems: prov.instrumenList,
                        displayText: (instrumen) => instrumen.namaInstrumen,
                        itemValue: (instrumen) => instrumen.instrumenId,
                        searchFilter: (instrumen, query) =>
                            instrumen.namaInstrumen.toLowerCase().contains(query.toLowerCase()),
                        onChanged: (value) {
                          prov.selectedInstrumenFilter = value;
                          prov.applyFilters();
                        },
                        hint: "Cari berdasarkan nama instrumen...",
                      ),
                  ],
                ),
                SkBlock.lineWrap(
                  responsive: true,
                  spacing: 16,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDatePicker(
                        context: context,
                        label: "Tanggal Mulai",
                        icon: Icons.calendar_today,
                        date: prov.startDateFilter,
                        onChanged: (date) {
                          prov.startDateFilter = date;
                          prov.applyFilters();
                        },
                      ),
                    _buildDatePicker(
                        context: context,
                        label: "Tanggal Akhir",
                        icon: Icons.event,
                        date: prov.endDateFilter,
                        onChanged: (date) {
                          prov.endDateFilter = date;
                          prov.applyFilters();
                        },
                      ),
                  ],
                ),
                if (prov.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[700]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            prov.errorMessage!,
                            style: TextStyle(
                              color: Colors.red[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedDropdown<T>({
    required BuildContext context,
    required String label,
    required IconData icon,
    required String? value,
    required List<T> allItems,
    required String Function(T) displayText,
    required String Function(T) itemValue,
    required bool Function(T, String) searchFilter,
    required Function(String?) onChanged,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkBlock.sectionHeader(
          leading: Icon(icon, size: 18, color: blueHighlight),
          leadingSpacing: 8,
          title: label,
          titleStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: InputBorder.none,
              suffixIcon: IconButton(
                icon: const Icon(Icons.search, size: 20),
                onPressed: () {
                  _showEnhancedSearchDialog<T>(
                    context: context,
                    title: label,
                    icon: icon,
                    allItems: allItems,
                    displayText: displayText,
                    itemValue: itemValue,
                    searchFilter: searchFilter,
                    onSelected: onChanged,
                    hint: hint,
                  );
                },
              ),
            ),
            items: [
              DropdownMenuItem(
                value: null,
                child: Text(
                  "Semua ${label.replaceAll('Filter ', '')}",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ),
              ...allItems.map((item) => DropdownMenuItem(
                    value: itemValue(item),
                    child: Text(displayText(item)),
                  )),
            ],
            onChanged: onChanged,
            isExpanded: true,
            icon: const Icon(Icons.arrow_drop_down, size: 24),
          ),
        ),
      ],
    );
  }

  void _showEnhancedSearchDialog<T>({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<T> allItems,
    required String Function(T) displayText,
    required String Function(T) itemValue,
    required bool Function(T, String) searchFilter,
    required Function(String?) onSelected,
    required String hint,
  }) {
    final searchController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          final filteredItems = searchController.text.isEmpty
              ? allItems
              : allItems.where((item) => searchFilter(item, searchController.text)).toList();

          // `width * 0.5` jadi terlalu sempit (~180px) di HP untuk daftar
          // hasil — narrow pakai lebar layar penuh, lebar tetap di desktop.
          final Size screen = MediaQuery.of(context).size;
          final bool narrow = screen.width < SkBlock.compactBreakpoint;
          final double inset = narrow ? 12 : 40;
          final double dialogWidth =
              narrow ? screen.width - inset * 2 : screen.width * 0.5;

          return Dialog(
            insetPadding:
                EdgeInsets.symmetric(horizontal: inset, vertical: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: dialogWidth,
              constraints: BoxConstraints(
                maxHeight: screen.height * (narrow ? 0.9 : 0.85) < 600
                    ? screen.height * (narrow ? 0.9 : 0.85)
                    : 600,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: blueHighlight.withValues(alpha: 0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: SkBlock.sectionHeader(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      leading: Icon(icon, color: blueHighlight),
                      title: "Cari $title",
                      titleStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: blueHighlight,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(dialogContext),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: TextField(
                      controller: searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: hint,
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                  ),
                  Flexible(
                    child: filteredItems.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(40),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "Tidak ada data ditemukan",
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: filteredItems.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = filteredItems[index];
                              return ListTile(
                                title: Text(displayText(item)),
                                trailing: const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                ),
                                onTap: () {
                                  onSelected(itemValue(item));
                                  Navigator.pop(dialogContext);
                                },
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                hoverColor: blueHighlight.withValues(alpha: 0.05),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDatePicker({
    required BuildContext context,
    required String label,
    required IconData icon,
    required DateTime? date,
    required Function(DateTime?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkBlock.sectionHeader(
          leading: Icon(icon, size: 18, color: blueHighlight),
          leadingSpacing: 8,
          title: label,
          titleStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: blueHighlight,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              onChanged(picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    date != null
                        ? DateFormat('dd/MM/yyyy').format(date)
                        : 'Pilih tanggal',
                    style: TextStyle(
                      color: date != null ? Colors.black87 : Colors.grey[600],
                    ),
                  ),
                ),
                Icon(Icons.calendar_today, size: 18, color: Colors.grey[600]),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChartsSection(
      BuildContext context, ManageAsesmenPsikologisProvider prov) {
    // Bukan lineWrap: itu membungkus tiap anak Expanded(flex:1), sedangkan
    // susunan chart ini 2:1 — jadi percabangannya ditulis langsung.
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool compact = constraints.maxWidth.isFinite &&
            constraints.maxWidth < SkBlock.compactBreakpoint;

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildLineChart(context, prov),
              const SizedBox(height: 20),
              _buildDistributionChart(context, prov),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildLineChart(context, prov),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildDistributionChart(context, prov),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLineChart(
      BuildContext context, ManageAsesmenPsikologisProvider prov) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: SkBlock.sectionHeader(
              leading: const Icon(Icons.show_chart, color: Colors.blue),
              title: "Tren Skor Asesmen",
              titleStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              height: 300,
              child: SfCartesianChart(
                primaryXAxis: CategoryAxis(
                  title: const AxisTitle(
                    text: 'Tanggal',
                    textStyle: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  labelRotation: prov.chartLabels.length > 5 ? 45 : 0,
                  majorGridLines: const MajorGridLines(width: 0),
                ),
                primaryYAxis: const NumericAxis(
                  title: AxisTitle(
                    text: 'Skor Total',
                    textStyle: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  axisLine: AxisLine(width: 0),
                ),
                tooltipBehavior: TooltipBehavior(
                  enable: true,
                  color: blueHighlight,
                  textStyle: const TextStyle(color: Colors.white),
                ),
                legend: const Legend(
                  isVisible: true,
                  position: LegendPosition.bottom,
                ),
                series: <CartesianSeries>[
                  SplineAreaSeries<ChartData, String>(
                    dataSource: List.generate(
                      prov.chartData.length,
                      (index) => ChartData(
                        prov.chartLabels[index],
                        prov.chartData[index],
                      ),
                    ),
                    xValueMapper: (ChartData data, _) => data.label,
                    yValueMapper: (ChartData data, _) => data.value,
                    name: 'Skor',
                    color: blueHighlight.withValues(alpha: 0.3),
                    borderColor: blueHighlight,
                    borderWidth: 3,
                    markerSettings: const MarkerSettings(
                      isVisible: true,
                      shape: DataMarkerType.circle,
                      color: blueHighlight,
                      borderColor: Colors.white,
                      borderWidth: 2,
                    ),
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: true,
                      textStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionChart(
      BuildContext context, ManageAsesmenPsikologisProvider prov) {
    final distribution = prov.getScoreDistribution();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.purple.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: SkBlock.sectionHeader(
              leading: const Icon(Icons.pie_chart, color: Colors.purple),
              title: "Distribusi Interpretasi",
              titleStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              height: 300,
              child: distribution.isEmpty
                  ? _buildEmptyChartState()
                  : SfCircularChart(
                      tooltipBehavior: TooltipBehavior(enable: true),
                      legend: const Legend(
                        isVisible: true,
                        position: LegendPosition.bottom,
                        overflowMode: LegendItemOverflowMode.wrap,
                      ),
                      series: <CircularSeries>[
                        DoughnutSeries<Map<String, dynamic>, String>(
                          dataSource: distribution,
                          xValueMapper: (Map<String, dynamic> data, _) =>
                              data['category'] as String,
                          yValueMapper: (Map<String, dynamic> data, _) =>
                              data['count'] as int,
                          pointColorMapper: (Map<String, dynamic> data, _) =>
                              data['color'] as Color,
                          dataLabelSettings: const DataLabelSettings(
                            isVisible: true,
                            labelPosition: ChartDataLabelPosition.outside,
                            textStyle: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          dataLabelMapper: (Map<String, dynamic> data, _) =>
                              '${data['category']}\n${data['count']}',
                          innerRadius: '60%',
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChartState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            "Tidak ada data untuk diagram",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListSection(
      BuildContext context, ManageAsesmenPsikologisProvider prov) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: SkBlock.sectionHeader(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              leading: const Icon(Icons.list_alt, color: Colors.green),
              title: "Daftar Asesmen",
              titleStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
              trailing: Text(
                "${prov.filteredAsesmenList.length} data",
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: prov.isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : prov.filteredAsesmenList.isEmpty
                    ? _buildEmptyState()
                    : Column(
                        children: prov.filteredAsesmenList.map((asesmen) {
                          return _buildAsesmenCard(context, prov, asesmen);
                        }).toList(),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.inbox,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              "Tidak ada data asesmen",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Coba ubah filter atau buat asesmen baru",
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAsesmenCard(BuildContext context,
      ManageAsesmenPsikologisProvider prov, AsesmenPsikologisModel asesmen) {
    final pasienName = prov.getPasienName(asesmen.pasienId);
    final instrumenName = prov.getInstrumenName(asesmen.instrumenId);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.grey[50]!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // overflowWrap, bukan sectionHeader: subjudulnya widget (ikon +
            // nama), sedangkan subtitle sectionHeader cuma menerima String.
            SkBlock.overflowWrap(
              spacing: 12,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: blueHighlight.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.psychology,
                        color: blueHighlight,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            instrumenName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.person,
                                  size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  pasienName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        blueHighlight,
                        blueHighlight.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: blueHighlight.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.score, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        "${asesmen.skorTotal}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            SkBlock.lineWrap(
              responsive: true,
              spacing: 12,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInfoChip(
                  icon: Icons.calendar_today,
                  label: "Tanggal",
                  value: asesmen.tanggalAsesmen != null
                      ? DateFormat('dd/MM/yyyy')
                          .format(asesmen.tanggalAsesmen!)
                      : '-',
                  color: Colors.blue,
                ),
                _buildInfoChip(
                  icon: Icons.analytics,
                  label: "Interpretasi",
                  value: asesmen.hasilInterpretasi,
                  color: _getInterpretationColor(asesmen.hasilInterpretasi),
                ),
              ],
            ),
            const SizedBox(height: 4),
            SkBlock.lineWrap(
              responsive: true,
              spacing: 12,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    _showDetailDialog(
                        context, asesmen, pasienName, instrumenName);
                  },
                  icon: const Icon(Icons.visibility, size: 18),
                  label: const Text("DETAIL"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: blueHighlight,
                    side: const BorderSide(color: blueHighlight),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    _showDeleteDialog(context, prov, asesmen, instrumenName);
                  },
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text("HAPUS"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkBlock.sectionHeader(
            leading: Icon(icon, size: 14, color: color),
            leadingSpacing: 6,
            title: label,
            titleStyle: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getInterpretationColor(String interpretation) {
    switch (interpretation.toLowerCase()) {
      case 'mild anxiety':
        return Colors.blue;
      case 'moderate anxiety':
        return Colors.orange;
      case 'severe anxiety':
        return Colors.red;
      case 'very severe anxiety':
        return Colors.purple;
      case 'normal':
        return Colors.green;
      case 'mild depression':
        return Colors.blue;
      case 'moderate depression':
        return Colors.orange;
      case 'severe depression':
        return Colors.red;
      case 'very severe depression':
        return Colors.purple;
      case 'tinggi':
        return Colors.red;
      case 'sedang':
        return Colors.orange;
      case 'rendah':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _showDetailDialog(BuildContext context, AsesmenPsikologisModel asesmen,
      String pasienName, String instrumenName) {
    final provider = context.read<ManageAsesmenPsikologisProvider>();
    final futureDetail = provider.getDetailAsesmen(asesmen.asesmenId);

    showDialog(
      context: context,
      builder: (context) => DetailAsesmenDialog(
        asesmen: asesmen,
        pasienName: pasienName,
        instrumenName: instrumenName,
        futureDetail: futureDetail,
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    ManageAsesmenPsikologisProvider prov,
    AsesmenPsikologisModel asesmen,
    String instrumenName,
  ) async {
    final pasienName = prov.getPasienName(asesmen.pasienId);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => defaultConfirmationDialog(
        context: context,
        title: const Text("Hapus Asesmen"),
        content: Text(
          "Apakah Anda yakin ingin menghapus asesmen $instrumenName untuk pasien $pasienName?",
        ),
      ),
    );

    if (confirm == true) {
      final success = await prov.deleteAsesmen(asesmen.asesmenId);

      if (!context.mounted) return;

      if (success) {
        await showDialog(
          context: context,
          builder: (context) => defaultSuccessDialog(
            context: context,
            title: const Text("Berhasil Dihapus!"),
            content: Text(
              "Asesmen $instrumenName untuk pasien $pasienName berhasil dihapus.",
            ),
          ),
        );
      } else {
        await showErrorDialog(context: context);
      }
    }
  }
}


class DetailAsesmenDialog extends StatefulWidget {
  final AsesmenPsikologisModel asesmen;
  final String pasienName;
  final String instrumenName;
  final Future<List<Map<String, dynamic>>> futureDetail;

  const DetailAsesmenDialog({
    super.key,
    required this.asesmen,
    required this.pasienName,
    required this.instrumenName,
    required this.futureDetail,
  });

  @override
  State<DetailAsesmenDialog> createState() => _DetailAsesmenDialogState();
}

class _DetailAsesmenDialogState extends State<DetailAsesmenDialog> {
  @override
  Widget build(BuildContext context) {
    // Inset dinamis (pola sama dengan defaultDialog): insetPadding tetap 40
    // menghabiskan seperempat lebar di HP.
    final Size screen = MediaQuery.of(context).size;
    final bool narrow = screen.width < SkBlock.compactBreakpoint;
    final double inset = narrow ? 12 : 40;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: inset, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 700),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    blueHighlight,
                    blueHighlight.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: SkBlock.sectionHeader(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                leading:
                    const Icon(Icons.article, color: Colors.white, size: 28),
                title: "Detail Asesmen Psikologis",
                titleStyle: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                subtitle: widget.instrumenName,
                subtitleStyle: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkBlock.lineWrap(
                      responsive: true,
                      spacing: 16,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSummaryCard(
                          icon: Icons.person,
                          label: "Pasien",
                          value: widget.pasienName,
                          color: Colors.blue,
                        ),
                        _buildSummaryCard(
                          icon: Icons.calendar_today,
                          label: "Tanggal",
                          value: widget.asesmen.tanggalAsesmen != null
                              ? DateFormat('dd MMM yyyy HH:mm')
                                  .format(widget.asesmen.tanggalAsesmen!)
                              : '-',
                          color: Colors.green,
                        ),
                      ],
                    ),
                    SkBlock.lineWrap(
                      responsive: true,
                      spacing: 16,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSummaryCard(
                          icon: Icons.score,
                          label: "Skor Total",
                          value: widget.asesmen.skorTotal.toString(),
                          color: Colors.orange,
                        ),
                        _buildSummaryCard(
                          icon: Icons.analytics,
                          label: "Interpretasi",
                          value: widget.asesmen.hasilInterpretasi,
                          color: Colors.purple,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SkBlock.sectionHeader(
                      leading: const Icon(Icons.list,
                          color: blueHighlight, size: 24),
                      title: "Detail Item Asesmen",
                      titleStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: blueHighlight,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailContent(),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(
                  top: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text("TUTUP"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkBlock.sectionHeader(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            title: label,
            titleStyle: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailContent() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: widget.futureDetail,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error, color: Colors.red[700], size: 48),
                  const SizedBox(height: 16),
                  Text(
                    "Error: ${snapshot.error}",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red[700]),
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    "Tidak ada data item asesmen",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          );
        }

        final detailData = snapshot.data!;

        return Column(
          children: detailData.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final itemAsesmen =
                item['item_asesmen'] as ItemAsesmenPsikologisModel;
            final instrumenItem = item['instrumen_item'] as InstrumenItemModel;

            return _buildQuestionItem(
              index: index,
              instrumenItem: instrumenItem,
              skor: itemAsesmen.skor,
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildQuestionItem({
    required int index,
    required InstrumenItemModel instrumenItem,
    required int skor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [blueHighlight, Colors.blue],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      "${instrumenItem.nomerItem}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        instrumenItem.pertanyaan,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (instrumenItem.teksPertanyaan.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            instrumenItem.teksPertanyaan,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            SkBlock.overflowWrap(
              spacing: 12,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: blueHighlight.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.category,
                        size: 16,
                        color: blueHighlight,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          "Skoring: ${instrumenItem.kategoriSkoring}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: blueHighlight,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.green, Colors.lightGreen],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "Skor:",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        skor.toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}