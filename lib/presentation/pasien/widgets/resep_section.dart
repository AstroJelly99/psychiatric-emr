import 'package:flutter/material.dart';
import 'package:emr_homemade/data/models/pasien_model.dart';
import 'package:emr_homemade/data/models/resep_model.dart';
import 'package:emr_homemade/domain/drug_interaction/drug_interaction_provider.dart';
import 'package:emr_homemade/presentation/drug_interaction/drug_interaction_dialog.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:emr_homemade/domain/resep/resep_provider.dart';
import 'package:emr_homemade/data/models/kunjungan_model.dart';
import 'package:emr_homemade/FBBlock/sk_block.dart';
import 'package:emr_homemade/utils/widgets/alert_dialogs.dart';
import 'package:intl/intl.dart';

class ResepSection extends StatefulWidget {
  final KunjunganModel kunjungan;
  final String pasienId;
  final PasienModel pasien; // Tambahkan parameter pasien

  const ResepSection({
    super.key,
    required this.kunjungan,
    required this.pasienId,
    required this.pasien, // Tambahkan di constructor
  });

  @override
  State<ResepSection> createState() => _ResepSectionState();
}

class _ResepSectionState extends State<ResepSection> {
  bool _showResepForm = false;
  List<String> _allergyWarnings = []; // Untuk tracking warnings

  /// Kartu riwayat resep terbuka secara bawaan: inilah yang dicari dokter
  /// saat menulis resep, jadi tidak masuk akal menyembunyikannya di balik
  /// satu ketukan tambahan.
  bool _riwayatTerbuka = true;

  /// Resep lama mana yang sedang ditampilkan. `null` = yang terbaru.
  String? _riwayatResepId;

  void _muatData() {
    final prov = Provider.of<ResepProvider>(context, listen: false);
    prov.loadResepByKunjunganId(widget.kunjungan.kunjunganId);
    // Riwayat dimuat bersamaan, bukan menunggu form dibuka: kalau menunggu,
    // dokter menekan "Tambah Resep" lalu menatap kartu kosong sesaat.
    prov.loadRiwayatResep(widget.pasien.pasienId);
  }

  /// Resep dari kunjungan LAIN. Penyaringan dilakukan di sini, bukan di
  /// provider, supaya kartu rujukan di form kunjungan tetap bisa memakai
  /// daftar yang sama dengan aturannya sendiri.
  List<ResepModel> _riwayatLain(ResepProvider prov) => prov.riwayatResep
      .where((r) => r.kunjunganId != widget.kunjungan.kunjunganId)
      .toList();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _muatData());
  }

  @override
  void didUpdateWidget(covariant ResepSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kunjungan.kunjunganId != widget.kunjungan.kunjunganId) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _muatData());
    }
  }

  /// Resep lama yang sedang ditampilkan di kartu rujukan.
  ResepModel? _resepRujukan(ResepProvider prov) {
    final list = _riwayatLain(prov);
    if (list.isEmpty) return null;
    if (_riwayatResepId == null) return list.first;
    return list.firstWhere(
      (r) => r.resepId == _riwayatResepId,
      orElse: () => list.first,
    );
  }

  Widget _buildRiwayatResep(BuildContext context, ResepProvider prov) {
    if (prov.riwayatLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final list = _riwayatLain(prov);
    final ResepModel? lama = _resepRujukan(prov);
    if (lama == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          "Belum ada resep dari kunjungan sebelumnya.",
          style: GoogleFonts.nunito(
            fontSize: 15,
            color: Colors.grey.shade700,
          ),
        ),
      );
    }

    final int urutan = list.indexOf(lama) + 1;

    return Container(
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _riwayatTerbuka = !_riwayatTerbuka),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
              child: SkBlock.sectionHeader(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                leading: Icon(Icons.medication_outlined,
                    color: Colors.amber.shade800, size: 22),
                leadingSpacing: 10,
                title: "Resep lama ($urutan dari ${list.length})",
                titleStyle: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade900,
                ),
                subtitle: DateFormat('EEEE, dd MMMM yyyy', 'id_ID')
                    .format(lama.tanggalResep),
                subtitleStyle: GoogleFonts.nunito(
                  fontSize: 14,
                  color: Colors.brown.shade700,
                ),
                trailing: Icon(
                  _riwayatTerbuka ? Icons.expand_less : Icons.expand_more,
                  color: Colors.amber.shade800,
                  size: 26,
                ),
              ),
            ),
          ),
          if (_riwayatTerbuka) ...[
            const Divider(height: 1),
            if (list.length > 1)
              _buildPemilihTanggalResep(list, lama),
            if (list.length > 1) const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kotak netral putih + aksen coklat — pola yang sama
                  // dipakai kartu "Kunjungan Lama" di KunjunganSection,
                  // supaya kedua kartu riwayat/rujukan ini kelihatan satu
                  // bahasa visual, bukan dua gaya berbeda.
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.brown.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkBlock.sectionHeader(
                          leading: Icon(Icons.medication_outlined,
                              size: 18, color: Colors.brown.shade700),
                          leadingSpacing: 8,
                          title: "ISI RESEP",
                          titleStyle: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.4,
                            color: Colors.brown.shade700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          lama.catatan.trim().isEmpty
                              ? "(kosong)"
                              : lama.catatan,
                          style: GoogleFonts.nunito(
                            fontSize: 15.5,
                            height: 1.45,
                            fontWeight: FontWeight.w600,
                            color: Colors.brown.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _gunakanResepLama(context, prov, lama),
                      icon: const Icon(Icons.content_copy, size: 20),
                      label: Text(
                        "GUNAKAN RESEP INI",
                        style: GoogleFonts.nunito(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade700,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Pemilih tanggal resep lama. Digulung mendatar dan dibungkus ClipRRect
  /// supaya chip yang keluar batas terpotong rapi mengikuti lengkung kartu,
  /// bukan menabrak garis tepinya.
  Widget _buildPemilihTanggalResep(List<ResepModel> list, ResepModel dipilih) {
    return SizedBox(
      height: 56,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final r = list[i];
          final bool aktif = r.resepId == dipilih.resepId;
          return InkWell(
            onTap: () => setState(() => _riwayatResepId = r.resepId),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: aktif ? Colors.amber.shade700 : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      aktif ? Colors.amber.shade700 : Colors.amber.shade300,
                ),
              ),
              child: Center(
                child: Text(
                  DateFormat('dd MMM yyyy', 'id_ID').format(r.tanggalResep),
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: aktif ? FontWeight.bold : FontWeight.w600,
                    color: aktif ? Colors.black : Colors.brown.shade700,
                  ),
                ),
              ),
            ),
          );
        },
      ),
      ),
    );
  }

  /// Menyalin isi resep lama ke kolom isian.
  ///
  /// Dikonfirmasi lebih dulu dan TIDAK pernah otomatis — sesuai permintaan.
  /// Setelah disalin, pengecekan alergi langsung dijalankan ulang: resep lama
  /// bisa saja memuat obat yang kini jadi alergi pasien, dan menyalinnya diam
  /// -diam tanpa memeriksa ulang justru memindahkan risiko, bukan menghemat
  /// waktu.
  Future<void> _gunakanResepLama(
    BuildContext context,
    ResepProvider prov,
    ResepModel lama,
  ) async {
    final bool? setuju = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => defaultConfirmationDialog(
        context: dialogContext,
        title: const Text("Gunakan resep ini?"),
        content: Text(
          "Isi resep akan diganti dengan resep tanggal "
          "${DateFormat('dd MMMM yyyy', 'id_ID').format(lama.tanggalResep)}.\n\n"
          "Periksa kembali dosis dan alerginya sebelum menyimpan.",
          style: GoogleFonts.nunito(fontSize: 15, height: 1.45),
        ),
      ),
    );

    if (setuju != true) return;

    prov.catatanTf.text = lama.catatan;
    _checkAllergies(lama.catatan);

    if (!context.mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Resep ${DateFormat('dd MMM yyyy', 'id_ID').format(lama.tanggalResep)}"
          " disalin. Periksa kembali sebelum menyimpan.",
          style: GoogleFonts.nunito(fontSize: 15),
        ),
        backgroundColor: Colors.amber.shade800,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _checkAllergies(String resepText) {
    if (widget.pasien.patientAllergy.isEmpty) {
      setState(() {
        _allergyWarnings = [];
      });
      return;
    }

    List<String> warnings = [];
    List<String> allergies = widget.pasien.patientAllergy
        .split(',')
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toList();

    List<String> words = resepText
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    for (String allergy in allergies) {
      if (words.contains(allergy)) {
        warnings.add(allergy);
      }
    }

    setState(() {
      _allergyWarnings = warnings;
    });
  }


  List<String> _extractDrugNames(String resepText) {
    if (resepText.trim().isEmpty) return [];

    List<String> drugNames = [];

  
    List<String> lines = resepText
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    for (String line in lines) {

      
      List<String> words = line.split(RegExp(r'\s+'));
      if (words.isNotEmpty) {
        String drugName = words[0].trim();
       
        if (drugName.isNotEmpty && drugName.length >= 3) {
          drugNames.add(drugName);
        }
      }
    }

    return drugNames;
  }


  void _handleCheckInteraction(BuildContext context) async {
    final resepProv = Provider.of<ResepProvider>(context, listen: false);
    String resepText = resepProv.catatanTf.text;

    if (resepText.trim().isEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return defaultInvalidDialog(
            context: context,
            content: const Text(
                "Mohon isi resep terlebih dahulu sebelum melakukan pengecekan interaksi!"),
          );
        },
      );
      return;
    }

    List<String> drugNames = _extractDrugNames(resepText);

    if (drugNames.isEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return defaultInvalidDialog(
            context: context,
            content: const Text(
                "Tidak dapat mengenali nama obat dari resep. Pastikan format resep benar."),
          );
        },
      );
      return;
    }

    final interactionProv =
        Provider.of<DrugInteractionProvider>(context, listen: false);
    interactionProv.reset();

    for (int i = 0; i < drugNames.length && i < 5; i++) {
      if (i == 0) {
        interactionProv.updateDrug(0, drugNames[i]);
      } else {
        interactionProv.addDrug();
        interactionProv.updateDrug(i, drugNames[i]);
      }
    }

    interactionProv.setShowDialog(true);
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return ChangeNotifierProvider.value(
          value: interactionProv,
          child: const DrugInteractionDialog(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ResepProvider>(
      builder: (context, resepProv, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SkBlock.sectionHeader(
                title: "Resep Medis",
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                titleStyle: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
                trailing: _showResepForm
                    ? null
                    : SkBlock.freeButton(
                        onTap: () {
                          resepProv.clearForm();
                          resepProv.setTanggalResep(
                              widget.kunjungan.tanggalKunjungan);
                          setState(() {
                            _showResepForm = true;
                            _allergyWarnings = [];
                          });
                        },
                        color: Colors.green.shade50,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.medical_services,
                                size: 18, color: Colors.green.shade700),
                            const SizedBox(width: 8),
                            Text(
                              "TAMBAH RESEP",
                              style: GoogleFonts.nunito(
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),

            if (widget.pasien.patientAllergy.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.red.shade300,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Alergi Pasien:",
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade800,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.pasien.patientAllergy,
                            style: GoogleFonts.nunito(
                              color: Colors.red.shade700,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            if (_showResepForm)
              _buildResepForm(context, resepProv)
            else if (resepProv.resepList.isNotEmpty)
              _buildResepList(resepProv)
            else
              _buildEmptyResepState(),

            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  Widget _buildEmptyResepState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.medication, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            "Belum ada resep",
            style: GoogleFonts.nunito(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Klik tombol 'Tambah Resep' untuk menambahkan resep obat",
            style: GoogleFonts.nunito(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildResepForm(BuildContext context, ResepProvider resepProv) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            resepProv.selectedResep == null
                ? "Tambah Resep Baru"
                : "Edit Resep",
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade800,
            ),
          ),

          const SizedBox(height: 16),

          // Riwayat resep dari kunjungan-kunjungan sebelumnya, tepat di atas
          // kolom isian. Meresepkan tanpa bisa melihat resep sebelumnya
          // adalah lubang yang berbahaya, bukan sekadar kurang nyaman.
          _buildRiwayatResep(context, resepProv),

          const SizedBox(height: 4),

          SkBlock.formField(
            primaryText: "Tanggal Resep",
            secondaryText: "Prescription Date (from visit date)",
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      DateFormat('dd MMMM yyyy')
                          .format(widget.kunjungan.tanggalKunjungan),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.calendar_today,
                      size: 20, color: Colors.grey.shade500),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          SkBlock.formField(
            primaryText: 'Isi Resep',
            secondaryText: 'Prescription Details',
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: resepProv.catatanTf,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText:
                      "Masukkan resep obat-obatan, dosis, aturan pakai, dan catatan lainnya...\n"
                      "Contoh:\n"
                      "sertraline 50 mg 1x1\n"
                      "clobazam 10 mg 2x 1/2",
                  hintStyle: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey.shade500,
                    height: 1.4,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
                style: GoogleFonts.nunito(fontSize: 14, height: 1.5),
                onChanged: (text) {
                  _checkAllergies(text);
                },
              ),
            ),
          ),

          if (_allergyWarnings.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade300, width: 2),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline,
                      color: Colors.red.shade700, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "⚠️ PERINGATAN ALERGI",
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade900,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Pasien memiliki alergi terhadap: ${_allergyWarnings.join(', ').toUpperCase()}",
                          style: GoogleFonts.nunito(
                            color: Colors.red.shade900,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Harap periksa kembali resep sebelum menyimpan!",
                          style: GoogleFonts.nunito(
                            color: Colors.red.shade800,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          SkBlock.lineWrap(
            responsive: true,
            spacing: 12,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SkBlock.freeButton(
                onTap: () {
                  resepProv.clearForm();
                  setState(() {
                    _showResepForm = false;
                    _allergyWarnings = [];
                  });
                },
                color: Colors.grey.shade300,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Text(
                  "BATAL",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: 15,
                  ),
                ),
              ),

              SkBlock.freeButton(
                onTap: () => _handleCheckInteraction(context),
                color: Colors.blue.shade100,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.psychology,
                        size: 18, color: Colors.blue.shade800),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        "CEK INTERAKSI",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SkBlock.freeButton(
                onTap: () => _saveResep(context, resepProv),
                color: Colors.green.shade600,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Text(
                  resepProv.selectedResep == null ? "SIMPAN" : "UPDATE",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResepList(ResepProvider resepProv) {
    return Column(
      children: [
        ...resepProv.resepList
            .map((resep) => _buildResepCard(resep, resepProv)),

        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Center(
            child: SkBlock.freeButton(
              onTap: () {
                resepProv.clearForm();
                resepProv.setTanggalResep(widget.kunjungan.tanggalKunjungan);
                setState(() {
                  _showResepForm = true;
                  _allergyWarnings = [];
                });
              },
              color: Colors.green.shade50,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 18, color: Colors.green.shade700),
                  const SizedBox(width: 8),
                  Text(
                    "TAMBAH RESEP BARU",
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResepCard(ResepModel resep, ResepProvider resepProv) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(Icons.medication,
                    color: Colors.green.shade700, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  DateFormat('dd MMMM yyyy').format(resep.tanggalResep),
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit, color: Colors.blue.shade700, size: 20),
                onPressed: () {
                  resepProv.setSelectedResep(resep);
                  setState(() {
                    _showResepForm = true;
                    _allergyWarnings = [];
                  });
                },
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red.shade700, size: 20),
                onPressed: () => _confirmDeleteResep(resep, resepProv),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Divider(color: Colors.grey.shade200),
          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              resep.catatan,
              style: GoogleFonts.nunito(
                fontSize: 14,
                height: 1.6,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveResep(BuildContext context, ResepProvider resepProv) async {
    if (resepProv.catatanTf.text.isEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return defaultInvalidDialog(
            context: context,
            content: const Text("Mohon isi field Isi Resep!"),
          );
        },
      );
      return;
    }

    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return defaultConfirmationDialog(
          context: context,
          content: Text(
            resepProv.selectedResep == null
                ? "Tambahkan resep ini?"
                : "Update data resep ini?",
          ),
        );
      },
    );

    if (confirmed == true) {
      bool success;
      if (resepProv.selectedResep == null) {
        success = await resepProv.addResep(
            widget.pasienId, widget.kunjungan.kunjunganId);
      } else {
        success = await resepProv.updateResep(resepProv.createdBy ?? "system");
      }

      if (success && context.mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return defaultSuccessDialog(
              context: context,
              content: Text(
                resepProv.selectedResep == null
                    ? "Resep Berhasil ditambahkan!"
                    : "Data Resep Berhasil diupdate!",
              ),
            );
          },
        ).then((_) {
          setState(() {
            _showResepForm = false;
            _allergyWarnings = [];
          });
        });
      } else if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => defaultErrorDialog(),
        );
      }
    }
  }

  Future<void> _confirmDeleteResep(
      ResepModel resep, ResepProvider resepProv) async {
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return defaultConfirmationDialog(
          context: context,
          content: const Text("Hapus resep ini?"),
        );
      },
    );

    if (confirmed == true) {
      final success = await resepProv.deleteResep(
          resep.resepId, widget.kunjungan.kunjunganId);
      // `mounted` milik State, bukan `context.mounted` — di dalam State hanya
      // yang pertama yang menjamin widget masih hidup setelah await.
      if (success && mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return defaultSuccessDialog(
              context: context,
              content: const Text("Resep berhasil dihapus!"),
            );
          },
        );
      }
    }
  }
}
