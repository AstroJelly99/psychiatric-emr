
import 'package:flutter/material.dart';
import 'package:emr_homemade/FBBlock/sk_block.dart';
import 'package:emr_homemade/domain/asesmen_psikologis/create_asesmen_psikologis_provider.dart';
import 'package:emr_homemade/utils/widgets/constant.dart';
import 'package:provider/provider.dart';

class CreateAsesmenPsikologisPage extends StatelessWidget {
  const CreateAsesmenPsikologisPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CreateAsesmenPsikologisProvider(context),
      child: Consumer<CreateAsesmenPsikologisProvider>(
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
                  child: SkBlock.lineBlock(
                    text: "Buat Asesmen Psikologis",
                    isHeader: true,
                    padding: const EdgeInsets.all(20),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 1400),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildProgressIndicator(prov),
                            const SizedBox(height: 24),
                            
                            if (prov.isLoading && prov.pasienList.isEmpty)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(40),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            else ...[
                              _buildStepCard(
                                stepNumber: 1,
                                title: "Pilih Data Pasien & Instrumen",
                                contentBottomPadding: 4,
                                child: _selectionFields(context, prov),
                              ),
                              const SizedBox(height: 20),
                              
                              if (prov.selectedInstrumenId != null &&
                                  prov.instrumenItems.isNotEmpty) ...[
                                _buildStepCard(
                                  stepNumber: 2,
                                  title: "Isi Kuesioner",
                                  child: _questionnaireFields(context, prov),
                                ),
                                const SizedBox(height: 20),
                              ],
                              
                              if (prov.instrumenItems.isNotEmpty &&
                                  prov.skorTotalController.text.isNotEmpty) ...[
                                _buildStepCard(
                                  stepNumber: 3,
                                  title: "Hasil Asesmen",
                                  child: _resultFields(context, prov),
                                ),
                                const SizedBox(height: 20),
                              ],
                              
                              if (prov.instrumenItems.isNotEmpty)
                                _submitSection(context, prov),
                            ],
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
      ),
    );
  }

  Widget _buildProgressIndicator(CreateAsesmenPsikologisProvider prov) {
    int currentStep = 0;
    if (prov.selectedInstrumenId != null) currentStep = 1;
    if (prov.instrumenItems.isNotEmpty && prov.skorTotalController.text.isNotEmpty) currentStep = 2;
    if (prov.formValid) currentStep = 3;

    return Container(
      padding: const EdgeInsets.all(24),
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
      // Stepper 4 label + 3 garis penghubung tidak muat di 360dp; di bawah
      // ambang diganti jadi teks + progress bar, bukan sekadar disusutkan.
      // LayoutBuilder (bukan MediaQuery): kartu ini di dalam area konten
      // PanelPage, lebih sempit dari lebar layar di tablet.
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool compact = constraints.maxWidth.isFinite &&
              constraints.maxWidth < SkBlock.compactBreakpoint;

          if (compact) return _buildCompactProgress(currentStep);

          return Row(
            children: [
              _buildStepIndicator(1, "Pilih Data", currentStep >= 0),
              Expanded(child: _buildStepLine(currentStep >= 1)),
              _buildStepIndicator(2, "Isi Kuesioner", currentStep >= 1),
              Expanded(child: _buildStepLine(currentStep >= 2)),
              _buildStepIndicator(3, "Hasil", currentStep >= 2),
              Expanded(child: _buildStepLine(currentStep >= 3)),
              _buildStepIndicator(4, "Simpan", currentStep >= 3),
            ],
          );
        },
      ),
    );
  }

  static const List<String> _stepLabels = [
    "Pilih Data",
    "Isi Kuesioner",
    "Hasil",
    "Simpan",
  ];

  /// Bentuk stepper di layar sempit: keempat langkah tetap terlihat (selesai
  /// = centang, berjalan = disorot, sisanya abu-abu) supaya dokter tahu apa
  /// yang menunggu di depan, bukan cuma "Langkah 2 dari 4". Garis penghubung
  /// antar-lingkaran sengaja dilepas — itu yang bikin versi desktop overflow
  /// di layar sempit.
  Widget _buildCompactProgress(int currentStep) {
    final int step = currentStep + 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "Langkah $step dari ${_stepLabels.length}",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          _stepLabels[currentStep],
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: blueHighlight,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < _stepLabels.length; i++)
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _compactStepDot(i, currentStep),
                    const SizedBox(height: 6),
                    Text(
                      _stepLabels[i],
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.25,
                        fontWeight:
                            i == currentStep ? FontWeight.bold : FontWeight.w500,
                        color: i <= currentStep ? blueHighlight : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _compactStepDot(int index, int currentStep) {
    final bool done = index < currentStep;
    final bool active = index == currentStep;

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: done || active ? blueHighlight : Colors.grey[200],
        shape: BoxShape.circle,
        border: active
            ? Border.all(color: blueHighlight.withValues(alpha: 0.35), width: 4)
            : null,
      ),
      child: Center(
        child: done
            ? const Icon(Icons.check, size: 18, color: Colors.white)
            : Text(
                "${index + 1}",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: active ? Colors.white : Colors.grey[600],
                ),
              ),
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? blueHighlight : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              step.toString(),
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? blueHighlight : Colors.grey[600],
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(bool isActive) {
    return Container(
      height: 2,
      margin: const EdgeInsets.only(bottom: 24),
      color: isActive ? blueHighlight : Colors.grey[300],
    );
  }

  /// [contentBottomPadding] ada khusus untuk isi yang memakai
  /// [SkBlock.lineWrap]: lineWrap selalu menambah padding bawah sebesar
  /// `spacing`-nya. Tanpa dikurangi di sini, kartunya jadi lebih tinggi di
  /// layar lebar dan itu perubahan tampilan desktop yang tidak diinginkan.
  Widget _buildStepCard({
    required int stepNumber,
    required String title,
    required Widget child,
    double contentBottomPadding = 20,
  }) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
              title: title,
              titleStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: blueHighlight,
              ),
              leading: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: blueHighlight,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    stepNumber.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, contentBottomPadding),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _selectionFields(
      BuildContext context, CreateAsesmenPsikologisProvider prov) {
    return Column(
      children: [
        SkBlock.lineWrap(
          responsive: true,
          spacing: 16,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEnhancedDropdown(
                context: context,
                primaryText: "Pilih Pasien",
                secondaryText: "Select Patient *",
                icon: Icons.person,
                value: prov.selectedPasienId,
                allItems: prov.pasienList,
                displayText: (item) => item.patientName,
                itemValue: (item) => item.pasienId,
                searchFilter: (item, query) =>
                    item.patientName.toLowerCase().contains(query.toLowerCase()) ||
                    item.patientPhone.contains(query),
                onChanged: (value) {
                  prov.selectedPasienId = value;
                  if (value != null) {
                    prov.loadKunjunganByPasien(value);
                  }
                  prov.selectedKunjunganId = null;
                  prov.selectedInstrumenId = null;
                  prov.instrumenItems.clear();
                  prov.refreshUi();
                },
                hint: "Cari berdasarkan nama atau telepon...",
              ),
            _buildEnhancedDropdown(
                context: context,
                primaryText: "Pilih Kunjungan",
                secondaryText: "Select Visit *",
                icon: Icons.event,
                value: prov.selectedKunjunganId,
                allItems: prov.kunjunganList,
                displayText: (item) => "Tanggal: ${_formatDate(item.tanggalKunjungan)}",
                itemValue: (item) => item.kunjunganId,
                searchFilter: (item, query) =>
                    item.tanggalKunjungan.toString().contains(query) ||
                    item.keluhanUtama.toLowerCase().contains(query.toLowerCase()),
                onChanged: (value) {
                  prov.selectedKunjunganId = value;
                  prov.refreshUi();
                },
                hint: "Cari berdasarkan tanggal...",
                enabled: prov.selectedPasienId != null,
              ),
            _buildEnhancedDropdown(
                context: context,
                primaryText: "Pilih Instrumen",
                secondaryText: "Select Instrument *",
                icon: Icons.assessment,
                value: prov.selectedInstrumenId,
                allItems: prov.instrumenList,
                displayText: (item) => item.namaInstrumen,
                itemValue: (item) => item.instrumenId,
                searchFilter: (item, query) =>
                    item.namaInstrumen.toLowerCase().contains(query.toLowerCase()),
                onChanged: (value) {
                  prov.selectedInstrumenId = value;
                  if (value != null) {
                    prov.loadInstrumenItems(value);
                  }
                  prov.refreshUi();
                },
                hint: "Cari berdasarkan nama instrumen...",
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildEnhancedDropdown<T>({
    required BuildContext context,
    required String primaryText,
    required String secondaryText,
    required IconData icon,
    required String? value,
    required List<T> allItems,
    required String Function(T) displayText,
    required String Function(T) itemValue,
    required bool Function(T, String) searchFilter,
    required Function(String?) onChanged,
    required String hint,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkBlock.sectionHeader(
          leading: Icon(icon, size: 20, color: blueHighlight),
          leadingSpacing: 8,
          subtitleSpacing: 0, // dua Text ini sengaja menempel, tanpa jarak.
          title: primaryText,
          titleStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          subtitle: secondaryText,
          subtitleStyle: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: enabled ? Colors.white : Colors.grey[100],
            border: Border.all(
              color: enabled ? Colors.grey[300]! : Colors.grey[200]!,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: InputBorder.none,
              suffixIcon: enabled
                  ? IconButton(
                      icon: const Icon(Icons.search, size: 20),
                      onPressed: () {
                        _showEnhancedSearchDialog<T>(
                          context: context,
                          title: primaryText,
                          icon: icon,
                          allItems: allItems,
                          displayText: displayText,
                          itemValue: itemValue,
                          searchFilter: searchFilter,
                          onSelected: onChanged,
                          hint: hint,
                        );
                      },
                    )
                  : null,
            ),
            items: [
              DropdownMenuItem(
                value: null,
                child: Text(
                  enabled ? "Pilih $primaryText" : "Pilih pasien terlebih dahulu",
                  style: TextStyle(
                    color: enabled ? Colors.grey[600] : Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
              ),
              ...allItems.map((item) => DropdownMenuItem(
                    value: itemValue(item),
                    child: Text(displayText(item)),
                  )),
            ],
            onChanged: enabled ? onChanged : null,
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

          // `width * 0.5` aman di layar lebar tapi jadi ~180px (terlalu
          // sempit buat daftar hasil) di HP — narrow pakai lebar layar penuh.
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

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  Widget _questionnaireFields(
      BuildContext context, CreateAsesmenPsikologisProvider prov) {
    if (prov.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      children: prov.instrumenItems.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final options = prov.getSkoringOptions(item.kategoriSkoring);

        return Container(
          margin: EdgeInsets.only(bottom: index < prov.instrumenItems.length - 1 ? 16 : 0),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
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
                      color: blueHighlight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        "${item.nomerItem}",
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
                          item.pertanyaan,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (item.teksPertanyaan.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              item.teksPertanyaan,
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
              SkBlock.sectionHeader(
                leading:
                    const Icon(Icons.score, size: 18, color: blueHighlight),
                leadingSpacing: 8,
                title: "Pilih Skor (${item.kategoriSkoring})",
                titleStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: options.map((score) {
                  final isSelected = prov.skorControllers[item.instrumenItemId]
                          ?.text ==
                      score.toString();
                  return InkWell(
                    onTap: () {
                      prov.skorControllers[item.instrumenItemId]?.text =
                          score.toString();
                      prov.calculateTotalSkor();
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isSelected ? blueHighlight : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? blueHighlight : Colors.grey[300]!,
                          width: 2,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: blueHighlight.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          score.toString(),
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (prov.skorControllers[item.instrumenItemId]?.text.isNotEmpty ==
                  true)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: SkBlock.sectionHeader(
                      leading: const Icon(Icons.check_circle,
                          color: Colors.green, size: 20),
                      leadingSpacing: 8,
                      title:
                          "Skor terpilih: ${prov.skorControllers[item.instrumenItemId]!.text}",
                      titleStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _resultFields(
      BuildContext context, CreateAsesmenPsikologisProvider prov) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            blueHighlight.withValues(alpha: 0.1),
            blueHighlight.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: blueHighlight.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          SkBlock.sectionHeader(
            leading: const Icon(Icons.analytics, color: blueHighlight, size: 28),
            title: "Ringkasan Hasil Asesmen",
            titleStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: blueHighlight,
            ),
          ),
          const SizedBox(height: 24),
          SkBlock.lineWrap(
            responsive: true,
            spacing: 16,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildResultCard(
                label: "Total Skor",
                value: prov.skorTotalController.text,
                icon: Icons.score,
                color: Colors.blue,
              ),
              _buildResultCard(
                label: "Interpretasi",
                value: prov.hasilInterpretasiController.text,
                icon: Icons.psychology,
                color: Colors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkBlock.sectionHeader(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            title: label,
            titleStyle: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: label == "Interpretasi" ? 18 : 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _submitSection(
      BuildContext context, CreateAsesmenPsikologisProvider prov) {
    return Column(
      children: [
        if (prov.errorMessage != null)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(12),
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
        Center(
          // maxWidth (bukan SizedBox(width: 300)): tombol menyusut mengikuti
          // ruang yang ada di HP, alih-alih memaksa 300px.
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
              onPressed: prov.isLoading
                  ? null
                  : () {
                      prov.handleSubmit(context);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: prov.formValid ? blueHighlight : Colors.grey[400]!,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: prov.formValid ? 2 : 0,
              ),
              child: prov.isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.save, color: Colors.white),
                        SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            "SIMPAN ASESMEN",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 16,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
