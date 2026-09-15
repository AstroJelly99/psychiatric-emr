import 'package:flutter/material.dart';
import 'package:emr_homemade/data/models/kunjungan_model.dart';
import 'package:emr_homemade/data/models/pasien_model.dart';
import 'package:emr_homemade/domain/asesmen_psikologis/asesmen_section_provider.dart';
import 'package:emr_homemade/domain/kunjungan/kunjungan_provider.dart';
import 'package:emr_homemade/domain/resep/resep_provider.dart';
import 'package:emr_homemade/FBBlock/sk_block.dart';
import 'package:emr_homemade/presentation/asesmen/asesmen_section.dart';
import 'package:emr_homemade/presentation/pasien/widgets/resep_section.dart';
import 'package:emr_homemade/utils/widgets/alert_dialogs.dart';
import 'package:emr_homemade/utils/widgets/constant.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class KunjunganSection extends StatefulWidget {
  final String pasienId;
  final PasienModel? pasien;

  const KunjunganSection({
    super.key,
    required this.pasienId,
    required this.pasien,
  });

  @override
  State<KunjunganSection> createState() => _KunjunganSectionState();
}

class _KunjunganSectionState extends State<KunjunganSection> {
  bool _showKunjunganForm = false;
  KunjunganModel? _selectedKunjungan;

  /// Kartu rujukan kunjungan terakhir dibuka secara bawaan. Kalau tertutup,
  /// dokter harus tahu dulu bahwa kartunya ada sebelum bisa memakainya —
  /// padahal justru inilah jawaban atas "ingin melihat yang lama sambil
  /// mengisi yang baru".
  bool _rujukanTerbuka = true;

  /// Kunjungan mana yang sedang ditampilkan di kartu rujukan. `null` berarti
  /// "yang terbaru" — sengaja disimpan sebagai id, bukan sebagai objek, supaya
  /// pilihan dokter tetap benar setelah daftarnya dimuat ulang dari server.
  String? _rujukanId;

  DateTimeRange? _dateRange;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Resep dan asesmen pasien dimuat DI SINI, bukan diserahkan ke
    // ResepSection/AsesmenSection. Kedua section itu hanya terpasang di dalam
    // panel detail kunjungan; saat form kunjungan terbuka mereka tidak ada di
    // pohon widget sama sekali, jadi tidak ada yang memicu pemuatannya dan
    // kartu rujukan akan selalu bilang "tidak ada resep".
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final pasienId = widget.pasien?.pasienId;
      if (pasienId == null) return;
      Provider.of<ResepProvider>(context, listen: false)
          .loadRiwayatResep(pasienId);
      Provider.of<AsesmenSectionProvider>(context, listen: false)
          .loadRiwayatAsesmen(pasienId);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<KunjunganModel> _getFilteredKunjungan(
      List<KunjunganModel> kunjunganList) {
    var filtered = kunjunganList;

    if (_dateRange != null) {
      filtered = filtered.where((k) {
        return k.tanggalKunjungan
                .isAfter(_dateRange!.start.subtract(const Duration(days: 1))) &&
            k.tanggalKunjungan
                .isBefore(_dateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((k) {
        return k.keluhanUtama
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            k.diagnosis.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            DateFormat('dd MMM yyyy')
                .format(k.tanggalKunjungan)
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<KunjunganProvider>(
      builder: (context, kunjunganProv, _) {
        final filteredKunjungan =
            _getFilteredKunjungan(kunjunganProv.kunjunganList);

        // Tombol Back milik Android (dan panah di AppBar, yang memanggil
        // Navigator.maybePop dan ikut menghormati PopScope) sebelumnya
        // langsung menutup seluruh halaman Detail Pasien — dari detail
        // kunjungan langsung terlempar ke daftar pasien, melewati daftar
        // kunjungannya. Sekarang Back menutup satu lapis dulu:
        //
        //   form terbuka       -> tutup form, kembali ke daftar
        //   detail terbuka     -> tutup detail, kembali ke daftar
        //   sudah di daftar    -> baru keluar dari halaman pasien
        //
        // PopScope diletakkan di sini, bukan di pasien_detail, karena state
        // yang menentukan lapisannya (_showKunjunganForm, _selectedKunjungan)
        // hidup di widget ini.
        final bool adaLapisanTerbuka =
            _showKunjunganForm || _selectedKunjungan != null;

        return PopScope(
          canPop: !adaLapisanTerbuka,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            setState(() {
              if (_showKunjunganForm) {
                _showKunjunganForm = false;
              } else {
                _selectedKunjungan = null;
              }
            });
          },
          child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          // Tiga keadaan saling menggantikan (bukan split view): form,
          // detail, atau daftar — satu hal per waktu, cocok buat layar HP.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_showKunjunganForm) ...[
                _buildEnhancedHeader(kunjunganProv),
                const SizedBox(height: 16),
                _buildRujukanKunjunganTerakhir(context, kunjunganProv),
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: _buildKunjunganForm(context, kunjunganProv),
                ),
              ] else if (_selectedKunjungan != null) ...[
                _buildDetailBackBar(),
                _buildKunjunganDetailPanel(_selectedKunjungan!, kunjunganProv),
              ] else ...[
                _buildEnhancedHeader(kunjunganProv),
                _buildFilterSection(kunjunganProv),
                _buildKunjunganList(filteredKunjungan, kunjunganProv),
              ],
            ],
          ),
          ),
        );
      },
    );
  }

  /// Semua kunjungan yang layak dijadikan rujukan saat mengisi form, terbaru
  /// lebih dulu.
  ///
  /// Kalau yang sedang dibuka adalah form EDIT, kunjungan yang sedang diedit
  /// itu sendiri dikeluarkan — merujuk ke dirinya sendiri tidak ada gunanya
  /// dan membingungkan.
  List<KunjunganModel> _daftarRujukan(KunjunganProvider prov) {
    final String? sedangDiedit = prov.selectedKunjungan?.kunjunganId;
    return prov.kunjunganList
        .where((k) => k.kunjunganId != sedangDiedit)
        .toList()
      ..sort((a, b) => b.tanggalKunjungan.compareTo(a.tanggalKunjungan));
  }

  /// Kunjungan yang sedang ditampilkan di kartu rujukan.
  ///
  /// Kalau dokter belum memilih apa pun, atau yang dipilihnya sudah tidak ada
  /// di daftar (mis. terhapus, atau daftarnya berubah karena berpindah dari
  /// form baru ke form edit), jatuh kembali ke yang terbaru — bukan ke null,
  /// supaya kartunya tidak pernah tiba-tiba kosong.
  KunjunganModel? _kunjunganRujukan(KunjunganProvider prov) {
    final list = _daftarRujukan(prov);
    if (list.isEmpty) return null;
    if (_rujukanId == null) return list.first;
    return list.firstWhere(
      (k) => k.kunjunganId == _rujukanId,
      orElse: () => list.first,
    );
  }

  Widget _buildRujukanKunjunganTerakhir(
      BuildContext context, KunjunganProvider prov) {
    final List<KunjunganModel> daftar = _daftarRujukan(prov);
    final KunjunganModel? lama = _kunjunganRujukan(prov);
    if (lama == null) return const SizedBox.shrink();

    final int urutan = daftar.indexOf(lama) + 1;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade300),
      ),
      
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _rujukanTerbuka = !_rujukanTerbuka),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
              child: SkBlock.sectionHeader(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                leading: Icon(Icons.history_rounded,
                    color: Colors.amber.shade800, size: 22),
                leadingSpacing: 10,
                title: "Kunjungan lama ($urutan dari ${daftar.length})",
                titleStyle: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade900,
                ),
                subtitle:
                    DateFormat('EEEE, dd MMMM yyyy', 'id_ID')
                        .format(lama.tanggalKunjungan),
                subtitleStyle: GoogleFonts.nunito(
                  fontSize: 14,
                  color: Colors.brown.shade700,
                ),
                trailing: Icon(
                  _rujukanTerbuka ? Icons.expand_less : Icons.expand_more,
                  color: Colors.amber.shade800,
                  size: 26,
                ),
              ),
            ),
          ),
          if (_rujukanTerbuka) ...[
            const Divider(height: 1),
            if (daftar.length > 1)
              SizedBox(
                height: 56,
                // ClipRRect: tanpa ini chip yang tergulung keluar batas
                // menabrak garis tepi kartu dan terlihat seperti rusak.
                // Sekarang terpotong rapi mengikuti lengkungnya, dan potongan
                // itu justru jadi petunjuk bahwa masih ada tanggal lain.
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                    itemCount: daftar.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                    final k = daftar[i];
                    final bool dipilih = k.kunjunganId == lama.kunjunganId;
                    return InkWell(
                      onTap: () =>
                          setState(() => _rujukanId = k.kunjunganId),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: dipilih
                              ? Colors.amber.shade700
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: dipilih
                                ? Colors.amber.shade700
                                : Colors.amber.shade300,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            DateFormat('dd MMM yyyy', 'id_ID')
                                .format(k.tanggalKunjungan),
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              fontWeight: dipilih
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              color: dipilih
                                  ? Colors.black
                                  : Colors.brown.shade700,
                            ),
                          ),
                        ),
                      ),
                    );
                    },
                  ),
                ),
              ),
            if (daftar.length > 1) const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _barisRujukan("Keluhan utama", lama.keluhanUtama,
                      ikon: Icons.description_outlined),
                  _barisRujukan("Diagnosis", lama.diagnosis,
                      ikon: Icons.local_hospital_outlined),
                  _barisRujukan("Terapi", lama.terapi,
                      ikon: Icons.healing_outlined),
                  _barisRujukan("Tanda vital", _ringkasanTandaVital(lama),
                      ikon: Icons.monitor_heart_outlined),
                  _rujukanResep(lama),
                  _rujukanAsesmen(lama),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: SkBlock.lineWrap(
                responsive: true,
                spacing: 10,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _bukaRujukanLengkap(context, lama),
                    icon: const Icon(Icons.open_in_full, size: 20),
                    label: Text("LIHAT LENGKAP",
                        style: GoogleFonts.nunito(
                            fontSize: 14, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.amber.shade900,
                      side: BorderSide(color: Colors.amber.shade700),
                      minimumSize: const Size.fromHeight(46),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _salinDariKunjungan(context, prov, lama),
                    icon: const Icon(Icons.content_copy, size: 20),
                    label: Text("SALIN KE FORM",
                        style: GoogleFonts.nunito(
                            fontSize: 14, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade700,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      minimumSize: const Size.fromHeight(46),
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

  /// Resep pada kunjungan lama [lama], difilter dari daftar resep pasien
  /// (tidak difilter di provider) supaya provider yang sama tetap dipakai
  /// dari tempat lain tanpa saringan.
  Widget _rujukanResep(KunjunganModel lama) {
    return Consumer<ResepProvider>(
      builder: (context, resepProv, _) {
        final resep = resepProv.riwayatResep
            .where((r) => r.kunjunganId == lama.kunjunganId)
            .toList();
        if (resep.isEmpty) {
          return _barisRujukan(
            "Resep",
            "Tidak ada resep pada kunjungan ini",
            warna: Colors.green,
            ikon: Icons.medication_outlined,
          );
        }
        return _barisRujukan(
          resep.length == 1 ? "Resep" : "Resep (${resep.length})",
          resep.map((r) => r.catatan.trim()).where((c) => c.isNotEmpty).join("\n\n"),
          warna: Colors.green,
          ikon: Icons.medication_outlined,
        );
      },
    );
  }

  Widget _rujukanAsesmen(KunjunganModel lama) {
    return Consumer<AsesmenSectionProvider>(
      builder: (context, asesmenProv, _) {
        final asesmen = asesmenProv.riwayatAsesmen
            .where((a) => a.kunjunganId == lama.kunjunganId)
            .toList();
        if (asesmen.isEmpty) {
          return _barisRujukan(
            "Asesmen",
            "Tidak ada asesmen pada kunjungan ini",
            warna: Colors.purple,
            ikon: Icons.psychology_outlined,
          );
        }
        final isi = asesmen
            .map((a) =>
                "${asesmenProv.getInstrumenName(a.instrumenId)}: "
                "skor ${a.skorTotal} — ${a.hasilInterpretasi}")
            .join("\n");
        return _barisRujukan(
          asesmen.length == 1 ? "Asesmen" : "Asesmen (${asesmen.length})",
          isi,
          warna: Colors.purple,
          ikon: Icons.psychology_outlined,
        );
      },
    );
  }

  /// Ringkasan tanda vital satu baris untuk kartu rujukan, mis.
  /// "TD 120/80 · Suhu 36.5 · Nadi 80 x/menit". Bagian yang kosong (mis.
  /// Nadi belum pernah diisi di kunjungan lama) dilewati, bukan ditampilkan
  /// sebagai "Nadi  x/menit" yang membingungkan.
  String _ringkasanTandaVital(KunjunganModel k) {
    final List<String> bagian = [
      if (k.tekananDarah.isNotEmpty) "TD ${k.tekananDarah}",
      if (k.suhu.isNotEmpty) "Suhu ${k.suhu}",
      if ((k.nadi ?? '').isNotEmpty) "Nadi ${k.nadi} x/menit",
      if ((k.respirationRate ?? '').isNotEmpty)
        "Napas ${k.respirationRate} x/menit",
    ];
    return bagian.join(" · ");
  }

  /// Satu baris kartu rujukan, selalu dibungkus kotak. [warna] null = netral
  /// (field klinis biasa); hijau/ungu dipakai konsisten dengan warna Resep
  /// dan Asesmen di tempat lain aplikasi.
  Widget _barisRujukan(
    String label,
    String isi, {
    MaterialColor? warna,
    IconData? ikon,
  }) {
    if (isi.trim().isEmpty) return const SizedBox.shrink();

    // warna null -> pakai Colors.brown sebagai netral, satu jalur kode buat
    // kedua kasus.
    final MaterialColor efektif = warna ?? Colors.brown;
    final Color bg = warna != null ? efektif.shade50 : Colors.white;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: efektif.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkBlock.sectionHeader(
              leading: Icon(ikon, size: 18, color: efektif.shade700),
              leadingSpacing: 8,
              title: label.toUpperCase(),
              titleStyle: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.4,
                color: efektif.shade700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isi,
              style: GoogleFonts.nunito(
                fontSize: 15.5,
                height: 1.45,
                fontWeight: FontWeight.w600,
                color: efektif.shade900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Membuka kunjungan lama utuh sebagai dialog, BUKAN dengan menukar
  /// tampilan. Menukar tampilan akan melepas form beserta seluruh ketikan
  /// yang belum disimpan.
  void _bukaRujukanLengkap(BuildContext context, KunjunganModel lama) {
    final Size screen = MediaQuery.of(context).size;
    final bool narrow = screen.width < SkBlock.compactBreakpoint;
    final double inset = narrow ? 12 : 40;

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: inset, vertical: 24),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: (screen.width - inset * 2).clamp(0.0, 700.0),
            maxHeight: screen.height * 0.88,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(18, 14, 8, 14),
                color: Colors.amber.shade100,
                child: SkBlock.sectionHeader(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  title: "Kunjungan Lama",
                  titleStyle: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade900,
                  ),
                  subtitle: DateFormat('EEEE, dd MMMM yyyy', 'id_ID')
                      .format(lama.tanggalKunjungan),
                  subtitleStyle: GoogleFonts.nunito(
                    fontSize: 14,
                    color: Colors.brown.shade700,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 26),
                    onPressed: () => Navigator.pop(dialogContext),
                  ),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailCard(
                      icon: Icons.description,
                        title: "Keluhan Utama",
                        content: lama.keluhanUtama,
                        color: Colors.blue.shade50,
                        iconColor: Colors.blue.shade700,
                      ),
                      if (lama.riwayatPenyakitSekarang.isNotEmpty)
                        _buildDetailCard(
                          icon: Icons.history,
                          title: "Riwayat Penyakit Sekarang",
                          content: lama.riwayatPenyakitSekarang,
                          color: Colors.purple.shade50,
                          iconColor: Colors.purple.shade700,
                        ),
                      _buildDetailCard(
                        icon: Icons.local_hospital,
                        title: "Diagnosis",
                        content: lama.diagnosis,
                        color: Colors.red.shade50,
                        iconColor: Colors.red.shade700,
                      ),
                      _buildDetailCard(
                        icon: Icons.healing,
                        title: "Terapi",
                        content: lama.terapi,
                        color: Colors.green.shade50,
                        iconColor: Colors.green.shade700,
                      ),
                      if (_hasMentalExaminationData(lama))
                        _buildMentalExaminationCard(lama),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Menyalin isi kunjungan lama ke form yang sedang terbuka.
  ///
  /// Dikonfirmasi lebih dulu dan sengaja TIDAK menyalin tanggal: tanggal
  /// kunjungan baru harus tetap hari ini. Yang disalin juga hanya field yang
  /// masih kosong-atau-ditimpa secara sadar, dan dokter diberi tahu bahwa
  /// isinya wajib diperiksa ulang — diagnosis lama yang lolos tersalin ke
  /// kunjungan baru adalah kesalahan rekam medis, bukan sekadar salah ketik.
  Future<void> _salinDariKunjungan(
    BuildContext context,
    KunjunganProvider prov,
    KunjunganModel lama,
  ) async {
    final bool? setuju = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => defaultConfirmationDialog(
        context: dialogContext,
        title: const Text("Salin kunjungan ini?"),
        content: Text(
          "Isi form akan ditimpa dengan data kunjungan "
          "${DateFormat('dd MMMM yyyy', 'id_ID').format(lama.tanggalKunjungan)}.\n\n"
          "Tanggal kunjungan baru tidak ikut disalin. Periksa kembali "
          "diagnosis dan terapinya sebelum menyimpan.",
          style: GoogleFonts.nunito(fontSize: 15, height: 1.45),
        ),
      ),
    );

    if (setuju != true) return;

    prov.keluhanUtamaTf.text = lama.keluhanUtama;
    prov.riwayatSekarangTf.text = lama.riwayatPenyakitSekarang;
    prov.riwayatDahuluTf.text = lama.riwayatPenyakitDahulu;
    prov.riwayatKeluargaTf.text = lama.riwayatPenyakitKeluarga;
    prov.pemeriksaanFisikTf.text = lama.pemeriksaanFisik;
    prov.tekananDarahTf.text = lama.tekananDarah;
    prov.suhuTf.text = lama.suhu;
    prov.nadiTf.text = lama.nadi ?? '';
    prov.respirationRateTf.text = lama.respirationRate ?? '';
    prov.skalaNyeriTf.text = lama.skalaNyeri;
    prov.diagnosisTf.text = lama.diagnosis;
    prov.terapiTf.text = lama.terapi;
    prov.noteTf.text = lama.note ?? '';

    prov.deskripsiUmumTf.text = lama.deskripsiUmum ?? '';
    prov.kontakTf.text = lama.kontak ?? '';
    prov.kesadaranTf.text = lama.kesadaran ?? '';
    prov.orientasiTf.text = lama.orientasi ?? '';
    prov.memoriTf.text = lama.memori ?? '';
    prov.konsentrasiTf.text = lama.konsentrasi ?? '';
    prov.moodTf.text = lama.mood ?? '';
    prov.prosesBerpikirTf.text = lama.prosesBerpikir ?? '';
    prov.persepsiTf.text = lama.persepsi ?? '';
    prov.kemauanTf.text = lama.kemauan ?? '';
    prov.psikomotorTf.text = lama.psikomotor ?? '';
    prov.intelegensiTf.text = lama.intelegensi ?? '';

    if (!context.mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Data kunjungan "
          "${DateFormat('dd MMM yyyy', 'id_ID').format(lama.tanggalKunjungan)}"
          " disalin. Periksa kembali sebelum menyimpan.",
          style: GoogleFonts.nunito(fontSize: 15),
        ),
        backgroundColor: Colors.amber.shade800,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Widget _buildEnhancedHeader(KunjunganProvider kunjunganProv) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [blueHighlight.withValues(alpha: 0.1), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      // overflowWrap: judul + tombol sebaris kalau muat, tumpuk kalau tidak
      // (dulu overflow di layar sempit karena tombol lebar tetap).
      child: SkBlock.overflowWrap(
        spacing: 16,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: blueHighlight,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: blueHighlight.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.medical_services,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),

              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Riwayat Kunjungan",
                      style: GoogleFonts.nunito(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: blueDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.receipt_long,
                              size: 14, color: Colors.blue.shade700),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              "${kunjunganProv.kunjunganList.length} Total Kunjungan",
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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

          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                kunjunganProv.clearForm();
                setState(() {
                  _showKunjunganForm = true;
                  _selectedKunjungan = null;
                });
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [blueHighlight, blueHighlight.withValues(alpha: 0.8)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: blueHighlight.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_circle_outline,
                        color: Colors.black, size: 20),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        "KUNJUNGAN BARU",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Pemilih rentang tanggal custom (bukan [showDateRangePicker] bawaan,
  /// yang full-screen di layar sempit) — pintasan cepat di atas, rentang
  /// bebas di bawah. Sengaja tanpa paket tambahan.
  Future<void> _pilihRentangTanggal(BuildContext context) async {
    final DateTime kini = DateTime.now();
    DateTime? mulai = _dateRange?.start;
    DateTime? akhir = _dateRange?.end;

    final Size layar = MediaQuery.of(context).size;
    final bool sempit = layar.width < SkBlock.compactBreakpoint;
    final double inset = sempit ? 12 : 40;

    final hasil = await showDialog<DateTimeRange?>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          Future<void> pilihSatu({required bool untukMulai}) async {
            final DateTime awal = untukMulai
                ? (mulai ?? kini.subtract(const Duration(days: 30)))
                : (akhir ?? kini);
            final dipilih = await showDatePicker(
              context: dialogContext,
              initialDate: awal,
              firstDate: DateTime(2000),
              lastDate: kini,
              helpText: untukMulai ? 'Tanggal mulai' : 'Tanggal akhir',
              builder: (ctx, child) => Theme(
                data: Theme.of(ctx).copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: blueHighlight,
                    onPrimary: Colors.black,
                  ),
                  // Teks kalender bawaan terlalu kecil untuk dibaca nyaman.
                  textTheme: Theme.of(ctx).textTheme.copyWith(
                        bodyLarge: GoogleFonts.nunito(fontSize: 17),
                        bodyMedium: GoogleFonts.nunito(fontSize: 16),
                        titleMedium: GoogleFonts.nunito(fontSize: 17),
                      ),
                ),
                child: child!,
              ),
            );
            if (dipilih == null) return;
            setDialogState(() {
              if (untukMulai) {
                mulai = dipilih;
                // Rentang terbalik tidak mungkin dimaksudkan. Diperbaiki
                // diam-diam alih-alih memunculkan pesan kesalahan.
                if (akhir != null && akhir!.isBefore(dipilih)) akhir = dipilih;
              } else {
                akhir = dipilih;
                if (mulai != null && mulai!.isAfter(dipilih)) mulai = dipilih;
              }
            });
          }

          Widget pintasan(String label, int hari) {
            return OutlinedButton(
              onPressed: () => setDialogState(() {
                akhir = kini;
                mulai = kini.subtract(Duration(days: hari));
              }),
              style: OutlinedButton.styleFrom(
                foregroundColor: blueDark,
                side: BorderSide(color: Colors.blue.shade200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              child: Text(label,
                  style: GoogleFonts.nunito(
                      fontSize: 16, fontWeight: FontWeight.w600)),
            );
          }

          Widget kolomTanggal(String label, DateTime? nilai, bool untukMulai) {
            return InkWell(
              onTap: () => pilihSatu(untukMulai: untukMulai),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(label,
                              style: GoogleFonts.nunito(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(
                            nilai == null
                                ? "Pilih tanggal"
                                : DateFormat('dd MMMM yyyy', 'id_ID')
                                    .format(nilai),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.nunito(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: nilai == null
                                  ? Colors.grey
                                  : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.event, size: 24, color: blueDark),
                  ],
                ),
              ),
            );
          }

          return Dialog(
            insetPadding:
                EdgeInsets.symmetric(horizontal: inset, vertical: 24),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: (layar.width - inset * 2).clamp(0.0, 460.0),
                maxHeight: layar.height * 0.9,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SkBlock.sectionHeader(
                      leading: const Icon(Icons.date_range,
                          color: blueDark, size: 26),
                      title: "Filter Tanggal Kunjungan",
                      titleMaxLines: 2,
                      titleStyle: GoogleFonts.nunito(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: blueDark,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text("Pilihan cepat",
                        style: GoogleFonts.nunito(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        pintasan("30 hari", 30),
                        pintasan("3 bulan", 90),
                        pintasan("6 bulan", 180),
                        pintasan("1 tahun", 365),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text("Atau tentukan sendiri",
                        style: GoogleFonts.nunito(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700)),
                    const SizedBox(height: 10),
                    kolomTanggal("Dari", mulai, true),
                    const SizedBox(height: 10),
                    kolomTanggal("Sampai", akhir, false),
                    const SizedBox(height: 22),
                    SkBlock.lineWrap(
                      responsive: true,
                      spacing: 10,
                      children: [
                        OutlinedButton(
                          onPressed: () =>
                              Navigator.pop(dialogContext, _kosongkanFilter),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            foregroundColor: Colors.red.shade700,
                            side: BorderSide(color: Colors.red.shade300),
                          ),
                          child: Text("HAPUS FILTER",
                              style: GoogleFonts.nunito(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                        ),
                        ElevatedButton(
                          onPressed: (mulai == null || akhir == null)
                              ? null
                              : () => Navigator.pop(
                                    dialogContext,
                                    DateTimeRange(
                                        start: mulai!, end: akhir!),
                                  ),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            backgroundColor: blueHighlight,
                            foregroundColor: Colors.black,
                            elevation: 0,
                          ),
                          child: Text("TERAPKAN",
                              style: GoogleFonts.nunito(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    if (!mounted) return;
    if (hasil == null) return;
    setState(() {
      _dateRange = identical(hasil, _kosongkanFilter) ? null : hasil;
    });
  }

  /// Penanda "hapus filter". Dipakai karena `null` dari showDialog sudah
  /// berarti "dialog dibatalkan" — dua hal yang berbeda dan tidak boleh
  /// tertukar.
  static final DateTimeRange _kosongkanFilter = DateTimeRange(
    start: DateTime.fromMillisecondsSinceEpoch(0),
    end: DateTime.fromMillisecondsSinceEpoch(0),
  );

  Widget _buildFilterSection(KunjunganProvider kunjunganProv) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: SkBlock.lineWrap(
        responsive: true,
        spacing: 12,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: "Cari berdasarkan keluhan atau diagnosis...",
                  hintStyle: GoogleFonts.nunito(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),

          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _pilihRentangTanggal(context),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _dateRange != null ? blueHighlight : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _dateRange != null
                        ? blueHighlight
                        : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.date_range,
                      size: 18,
                      color: _dateRange != null
                          ? Colors.black
                          : Colors.grey.shade700,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                      _dateRange != null
                          ? "${DateFormat('dd MMM').format(_dateRange!.start)} - ${DateFormat('dd MMM yyyy').format(_dateRange!.end)}"
                          : "Filter Tanggal",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: _dateRange != null
                            ? FontWeight.bold
                            : FontWeight.w600,
                        color: _dateRange != null
                            ? Colors.black
                            : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (_dateRange != null || _searchQuery.isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: () {
                  setState(() {
                    _dateRange = null;
                    _searchQuery = '';
                    _searchController.clear();
                  });
                },
                icon: const Icon(Icons.filter_alt_off),
                tooltip: "Hapus Filter",
                color: Colors.red.shade400,
              ),
            ),
        ],
      ),
    );
  }

  /// Sengaja bukan `Navigator.push`: PanelPage sudah punya [PopScope] sendiri
  /// buat tombol Back, jadi route baru di sini bikin dua penangan Back
  /// berebut. Ganti tampilan lewat `_selectedKunjungan` saja.
  Widget _buildDetailBackBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: blueDark),
            tooltip: "Kembali ke daftar kunjungan",
            onPressed: () => setState(() => _selectedKunjungan = null),
          ),
          Expanded(
            child: Text(
              "Riwayat Kunjungan",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: blueDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKunjunganList(
      List<KunjunganModel> kunjunganList, KunjunganProvider kunjunganProv) {
    if (kunjunganList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _searchQuery.isNotEmpty || _dateRange != null
                      ? Icons.search_off
                      : Icons.medical_services_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _searchQuery.isNotEmpty || _dateRange != null
                    ? "Tidak ada hasil"
                    : "Belum ada riwayat kunjungan",
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _searchQuery.isNotEmpty || _dateRange != null
                    ? "Coba ubah filter pencarian Anda"
                    : "Klik tombol 'Kunjungan Baru' untuk memulai",
                style: GoogleFonts.nunito(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Column, bukan ListView: daftar ini sekarang mengalir di dalam
    // SingleChildScrollView milik pasien_detail, jadi tingginya tak terbatas
    // dan ListView di posisi itu akan melempar "unbounded height". Dulu dia
    // aman hanya karena split view mematok tinggi 0.65 layar — patokan itulah
    // yang membuat ilustrasi kosongnya terpotong 72px dan 58px.
    //
    // `shrinkWrap: true` juga bukan jawabannya: shrinkWrap tetap melayout
    // SELURUH anak untuk mengukur dirinya, jadi tidak ada untung virtualisasi,
    // sementara scroll di dalam scroll justru menambah masalah gestur.
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < kunjunganList.length; i++) ...[
            if (i != 0) const SizedBox(height: 8),
            _buildKunjunganCard(kunjunganList[i], kunjunganProv),
          ],
        ],
      ),
    );
  }

  Widget _buildKunjunganCard(
      KunjunganModel kunjungan, KunjunganProvider kunjunganProv) {
    final isSelected = _selectedKunjungan?.kunjunganId == kunjungan.kunjunganId;
    final hasFullData =
        kunjungan.diagnosis.isNotEmpty && kunjungan.terapi.isNotEmpty;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            _selectedKunjungan = kunjungan;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? blueHighlight.withValues(alpha: 0.15) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? blueHighlight : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: blueHighlight.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isSelected ? blueHighlight : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      DateFormat('dd MMM yyyy')
                          .format(kunjungan.tanggalKunjungan),
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.black : Colors.blue.shade700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    hasFullData ? Icons.check_circle : Icons.pending,
                    size: 16,
                    color: hasFullData
                        ? Colors.green.shade600
                        : Colors.orange.shade600,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Text(
                kunjungan.keluhanUtama,
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: blueDark,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  Icon(Icons.local_hospital,
                      size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      kunjungan.diagnosis.isNotEmpty
                          ? kunjungan.diagnosis
                          : "Belum ada diagnosis",
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        color: kunjungan.diagnosis.isNotEmpty
                            ? Colors.grey.shade700
                            : Colors.grey.shade500,
                        fontStyle: kunjungan.diagnosis.isEmpty
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKunjunganDetailPanel(
      KunjunganModel kunjungan, KunjunganProvider kunjunganProv) {
    // Padding, bukan SingleChildScrollView: scroll halaman sudah disediakan
    // pasien_detail. Menyisakan SingleChildScrollView di sini berarti scroll
    // bersarang tanpa tinggi berbatas.
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkBlock.overflowWrap(
            spacing: 16,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkBlock.sectionHeader(
                leadingSpacing: 0,
                title: "Detail Kunjungan",
                titleStyle: GoogleFonts.nunito(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: blueDark,
                ),
                subtitle: DateFormat('EEEE, dd MMMM yyyy', 'id_ID')
                    .format(kunjungan.tanggalKunjungan),
                subtitleStyle: GoogleFonts.nunito(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              _buildActionButton(
                icon: Icons.edit_outlined,
                label: "Edit",
                backgroundColor: Colors.blue,
                textColor: Colors.black,
                onTap: () {
                  kunjunganProv.setSelectedKunjungan(kunjungan);
                  setState(() {
                    _showKunjunganForm = true;
                    _selectedKunjungan = null;
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 24),
          Divider(color: Colors.grey.shade300, thickness: 1),
          const SizedBox(height: 24),

          _buildDetailCard(
            icon: Icons.description,
            title: "Keluhan Utama",
            content: kunjungan.keluhanUtama,
            color: Colors.blue.shade50,
            iconColor: Colors.blue.shade700,
          ),

          if (kunjungan.riwayatPenyakitSekarang.isNotEmpty)
            _buildDetailCard(
              icon: Icons.history,
              title: "Riwayat Penyakit Sekarang",
              content: kunjungan.riwayatPenyakitSekarang,
              color: Colors.purple.shade50,
              iconColor: Colors.purple.shade700,
            ),

          if (kunjungan.riwayatPenyakitDahulu.isNotEmpty)
            _buildDetailCard(
              icon: Icons.history_toggle_off,
              title: "Riwayat Penyakit Dahulu",
              content: kunjungan.riwayatPenyakitDahulu,
              color: Colors.orange.shade50,
              iconColor: Colors.orange.shade700,
            ),

          if (kunjungan.riwayatPenyakitKeluarga.isNotEmpty)
            _buildDetailCard(
              icon: Icons.family_restroom,
              title: "Riwayat Penyakit Keluarga",
              content: kunjungan.riwayatPenyakitKeluarga,
              color: Colors.teal.shade50,
              iconColor: Colors.teal.shade700,
            ),

          if (kunjungan.pemeriksaanFisik.isNotEmpty ||
              kunjungan.tekananDarah.isNotEmpty ||
              kunjungan.suhu.isNotEmpty ||
              (kunjungan.nadi ?? '').isNotEmpty ||
              (kunjungan.respirationRate ?? '').isNotEmpty ||
              kunjungan.skalaNyeri.isNotEmpty)
            _buildExaminationCard(kunjungan),

          if (_hasMentalExaminationData(kunjungan))
            _buildMentalExaminationCard(kunjungan),

          if (kunjungan.diagnosis.isNotEmpty)
            _buildDetailCard(
              icon: Icons.healing,
              title: "Diagnosis",
              content: kunjungan.diagnosis,
              color: Colors.green.shade50,
              iconColor: Colors.green.shade700,
            ),

          if (kunjungan.terapi.isNotEmpty)
            _buildDetailCard(
              icon: Icons.medication,
              title: "Terapi",
              content: kunjungan.terapi,
              color: Colors.indigo.shade50,
              iconColor: Colors.indigo.shade700,
            ),

          if ((kunjungan.note ?? '').isNotEmpty)
            _buildDetailCard(
              icon: Icons.note_alt,
              title: "Catatan Tambahan",
              content: kunjungan.note!,
              color: Colors.amber.shade50,
              iconColor: Colors.amber.shade700,
            ),

          const SizedBox(height: 24),

          Center(
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _confirmDeleteKunjungan(kunjungan, kunjunganProv),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.delete_outline,
                          color: Colors.red.shade700, size: 20),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          "HAPUS KUNJUNGAN",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                            fontSize: 14,
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
          const SizedBox(height: 24),

          if (widget.pasien != null)
            AsesmenSection(
              kunjungan: kunjungan,
              pasienId: widget.pasienId,
              pasien: widget.pasien!,
            ),
          const SizedBox(height: 24),
          if (widget.pasien != null)
            ResepSection(
              kunjungan: kunjungan,
              pasienId: widget.pasienId,
              pasien: widget.pasien!,
            ),
        ],
      ),
    );
  }

  bool _hasMentalExaminationData(KunjunganModel kunjungan) {
    return (kunjungan.deskripsiUmum?.isNotEmpty ?? false) ||
        (kunjungan.kontak?.isNotEmpty ?? false) ||
        (kunjungan.kesadaran?.isNotEmpty ?? false) ||
        (kunjungan.orientasi?.isNotEmpty ?? false) ||
        (kunjungan.memori?.isNotEmpty ?? false) ||
        (kunjungan.konsentrasi?.isNotEmpty ?? false) ||
        (kunjungan.mood?.isNotEmpty ?? false) ||
        (kunjungan.prosesBerpikir?.isNotEmpty ?? false) ||
        (kunjungan.persepsi?.isNotEmpty ?? false) ||
        (kunjungan.kemauan?.isNotEmpty ?? false) ||
        (kunjungan.psikomotor?.isNotEmpty ?? false) ||
        (kunjungan.intelegensi?.isNotEmpty ?? false);
  }

  Widget _buildMentalExaminationCard(KunjunganModel kunjungan) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade50, Colors.deepPurple.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.psychology,
                    size: 22, color: Colors.purple.shade700),
              ),
              const SizedBox(width: 12),
              Text(
                "Pemeriksaan Mental",
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.purple.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                if (kunjungan.deskripsiUmum?.isNotEmpty ?? false)
                  _buildMentalExaminationRow(
                    "Deskripsi Umum",
                    kunjungan.deskripsiUmum!,
                    Icons.description,
                  ),
                if (kunjungan.kontak?.isNotEmpty ?? false)
                  _buildMentalExaminationRow(
                    "Kontak Verbal/Non Verbal",
                    kunjungan.kontak!,
                    Icons.contact_page,
                  ),
                if (kunjungan.kesadaran?.isNotEmpty ?? false)
                  _buildMentalExaminationRow(
                    "Kesadaran",
                    kunjungan.kesadaran!,
                    Icons.visibility,
                  ),
                if (kunjungan.orientasi?.isNotEmpty ?? false)
                  _buildMentalExaminationRow(
                    "Orientasi Waktu/Tempat/Orang",
                    kunjungan.orientasi!,
                    Icons.explore,
                  ),
                if (kunjungan.memori?.isNotEmpty ?? false)
                  _buildMentalExaminationRow(
                    "Memori/Daya Ingat",
                    kunjungan.memori!,
                    Icons.memory,
                  ),
                if (kunjungan.konsentrasi?.isNotEmpty ?? false)
                  _buildMentalExaminationRow(
                    "Konsentrasi/Atensi",
                    kunjungan.konsentrasi!,
                    Icons.center_focus_strong,
                  ),
                if (kunjungan.mood?.isNotEmpty ?? false)
                  _buildMentalExaminationRow(
                    "Mood/Afek",
                    kunjungan.mood!,
                    Icons.sentiment_satisfied,
                  ),
                if (kunjungan.prosesBerpikir?.isNotEmpty ?? false)
                  _buildMentalExaminationRow(
                    "Proses Berpikir",
                    kunjungan.prosesBerpikir!,
                    Icons.psychology_alt,
                  ),
                if (kunjungan.persepsi?.isNotEmpty ?? false)
                  _buildMentalExaminationRow(
                    "Persepsi",
                    kunjungan.persepsi!,
                    Icons.remove_red_eye,
                  ),
                if (kunjungan.kemauan?.isNotEmpty ?? false)
                  _buildMentalExaminationRow(
                    "Kemauan",
                    kunjungan.kemauan!,
                    Icons.trending_up,
                  ),
                if (kunjungan.psikomotor?.isNotEmpty ?? false)
                  _buildMentalExaminationRow(
                    "Psikomotor",
                    kunjungan.psikomotor!,
                    Icons.directions_run,
                  ),
                if (kunjungan.intelegensi?.isNotEmpty ?? false)
                  _buildMentalExaminationRow(
                    "Intelegensi",
                    kunjungan.intelegensi!,
                    Icons.lightbulb,
                    isLast: true,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMentalExaminationRow(String label, String value, IconData icon,
      {bool isLast = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 16, color: Colors.purple.shade700),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Text(
                  label,
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                    fontSize: 13,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  value,
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.bold,
                    color: blueDark,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast) Divider(color: Colors.grey.shade200, height: 1),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color backgroundColor,
    Color? textColor, // Parameter opsional untuk warna teks
    required VoidCallback onTap,
  }) {
    final foregroundColor = textColor ?? _getContrastColor(backgroundColor);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: backgroundColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: foregroundColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w600,
                  color: foregroundColor,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getContrastColor(Color color) {
    final brightness = ThemeData.estimateBrightnessForColor(color);
    return brightness == Brightness.dark ? Colors.white : Colors.black;
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
    required Color iconColor,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkBlock.sectionHeader(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            title: title,
            titleStyle: GoogleFonts.nunito(
              fontWeight: FontWeight.bold,
              color: iconColor,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: GoogleFonts.nunito(
              color: Colors.grey.shade800,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExaminationCard(KunjunganModel kunjungan) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.pink.shade50, Colors.red.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkBlock.sectionHeader(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.monitor_heart,
                  size: 22, color: Colors.red.shade700),
            ),
            title: "Hasil Pemeriksaan Fisik",
            titleStyle: GoogleFonts.nunito(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                if (kunjungan.pemeriksaanFisik.isNotEmpty)
                  _buildExaminationRow(
                    "Pemeriksaan",
                    kunjungan.pemeriksaanFisik,
                    Icons.medical_services,
                  ),
                if (kunjungan.tekananDarah.isNotEmpty)
                  _buildExaminationRow(
                    "Tekanan Darah",
                    kunjungan.tekananDarah,
                    Icons.favorite,
                  ),
                if (kunjungan.suhu.isNotEmpty)
                  _buildExaminationRow(
                    "Suhu Tubuh",
                    "${kunjungan.suhu} °C",
                    Icons.thermostat,
                  ),
                if ((kunjungan.nadi ?? '').isNotEmpty)
                  _buildExaminationRow(
                    "Nadi",
                    "${kunjungan.nadi} x/menit",
                    Icons.favorite_border,
                  ),
                if ((kunjungan.respirationRate ?? '').isNotEmpty)
                  _buildExaminationRow(
                    "Laju Napas",
                    "${kunjungan.respirationRate} x/menit",
                    Icons.air,
                  ),
                if (kunjungan.skalaNyeri.isNotEmpty)
                  _buildExaminationRow(
                    "Skala Nyeri",
                    kunjungan.skalaNyeri,
                    Icons.mood_bad,
                    isLast: true,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExaminationRow(String label, String value, IconData icon,
      {bool isLast = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 16, color: Colors.blue.shade700),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Text(
                  label,
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                    fontSize: 13,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  value,
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.bold,
                    color: blueDark,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast) Divider(color: Colors.grey.shade200, height: 1),
      ],
    );
  }

  /// Field teks bebas untuk form kunjungan: boleh dienter ke baris baru dan
  /// menerima karakter apa pun (angka, %, $, dsb) — sama seperti kolom "Isi
  /// Resep" di ResepSection.
  ///
  /// [SkBlock.formTextField] biasa membatasi ke huruf/angka/`,.` `/-?` saja
  /// dan satu baris — cocok untuk field pendek terstruktur (username, kode
  /// obat), tapi salah untuk catatan klinis bebas: karakter di luar
  /// daftarnya (mis. `%`, `$`) diam-diam tidak masuk sama sekali, dan Enter
  /// tidak bisa dipakai untuk pindah baris.
  Widget _fieldBebas({
    required String primaryText,
    String? secondaryText,
    required TextEditingController controller,
    String? hint,
    TextInputType? keyboardType,
  }) {
    return SkBlock.formTextField(
      primaryText: primaryText,
      secondaryText: secondaryText,
      controller: controller,
      hint: hint,
      keyboardType: keyboardType,
      maxLines: 4,
      inputFormatters: const [],
    );
  }

  Widget _buildKunjunganForm(
      BuildContext context, KunjunganProvider kunjunganProv) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: blueHighlight, width: 2),
        boxShadow: [
          BoxShadow(
            color: blueHighlight.withValues(alpha: 0.2),
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: blueHighlight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.edit_note,
                  color: Colors.black,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  kunjunganProv.selectedKunjungan == null
                      ? "Tambah Kunjungan Baru"
                      : "Edit Data Kunjungan",
                  style: GoogleFonts.nunito(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: blueDark,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  kunjunganProv.clearForm();
                  setState(() {
                    _showKunjunganForm = false;
                  });
                },
                icon: const Icon(Icons.close),
                tooltip: "Tutup Form",
              ),
            ],
          ),

          const SizedBox(height: 24),
          Divider(color: Colors.grey.shade300),
          const SizedBox(height: 24),

          _buildFormFieldSection(context, kunjunganProv),

          const SizedBox(height: 24),

          SkBlock.lineWrap(
            responsive: true,
            spacing: 12,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    kunjunganProv.clearForm();
                    setState(() {
                      _showKunjunganForm = false;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cancel, color: Colors.black, size: 18),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            "BATAL",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => _saveKunjungan(context, kunjunganProv),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [blueHighlight, blueHighlight.withValues(alpha: 0.8)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: blueHighlight.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          kunjunganProv.selectedKunjungan == null
                              ? Icons.save
                              : Icons.update,
                          color: Colors.black,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            kunjunganProv.selectedKunjungan == null
                                ? "SIMPAN"
                                : "UPDATE",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormFieldSection(
      BuildContext context, KunjunganProvider kunjunganProv) {
    return Column(
      children: [
        SkBlock.formField(
          primaryText: "Tanggal Kunjungan",
          secondaryText: "Visit Date",
          child: InkWell(
            onTap: () async {
              final selectedDate = await showDatePicker(
                context: context,
                initialDate: kunjunganProv.tanggalKunjungan ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: blueHighlight,
                        onPrimary: Colors.black,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (selectedDate != null) {
                kunjunganProv.setTanggalKunjungan(selectedDate);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      kunjunganProv.tanggalKunjungan != null
                          ? DateFormat('dd MMMM yyyy')
                              .format(kunjunganProv.tanggalKunjungan!)
                          : "Pilih Tanggal Kunjungan",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        color: kunjunganProv.tanggalKunjungan != null
                            ? Colors.black
                            : Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.calendar_today, size: 20, color: blueDark),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        _fieldBebas(
          primaryText: 'Keluhan Utama',
          secondaryText: 'Chief Complaint',
          controller: kunjunganProv.keluhanUtamaTf,
          hint: "Masukkan keluhan utama pasien...",
        ),

        const SizedBox(height: 16),

        _buildCollapsibleSection(
          title: "Riwayat Penyakit",
          icon: Icons.history,
          children: [
            _fieldBebas(
              primaryText: 'Riwayat Penyakit Sekarang',
              secondaryText: 'Present Illness History',
              controller: kunjunganProv.riwayatSekarangTf,
              hint: "Masukkan riwayat penyakit sekarang...",
            ),
            const SizedBox(height: 12),
            _fieldBebas(
              primaryText: 'Riwayat Penyakit Dahulu',
              secondaryText: 'Past Medical History',
              controller: kunjunganProv.riwayatDahuluTf,
              hint: "Masukkan riwayat penyakit dahulu...",
            ),
            const SizedBox(height: 12),
            _fieldBebas(
              primaryText: 'Riwayat Penyakit Keluarga',
              secondaryText: 'Family Medical History',
              controller: kunjunganProv.riwayatKeluargaTf,
              hint: "Masukkan riwayat penyakit keluarga...",
            ),
          ],
        ),

        const SizedBox(height: 16),

        _buildCollapsibleSection(
          title: "Pemeriksaan Fisik",
          icon: Icons.monitor_heart,
          children: [
            _fieldBebas(
              primaryText: 'Pemeriksaan Fisik',
              secondaryText: 'Physical Examination',
              controller: kunjunganProv.pemeriksaanFisikTf,
              hint: "Masukkan hasil pemeriksaan fisik...",
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _fieldBebas(
                    primaryText: 'Tekanan Darah',
                    secondaryText: 'Blood Pressure',
                    controller: kunjunganProv.tekananDarahTf,
                    hint: "120/80 mmHg",
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _fieldBebas(
                    primaryText: 'Suhu',
                    secondaryText: 'Temperature',
                    controller: kunjunganProv.suhuTf,
                    hint: "36.5 °C",
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _fieldBebas(
                    primaryText: 'Nadi',
                    secondaryText: 'Pulse Rate',
                    controller: kunjunganProv.nadiTf,
                    hint: "80 x/menit",
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _fieldBebas(
                    primaryText: 'Laju Napas',
                    secondaryText: 'Respiration Rate',
                    controller: kunjunganProv.respirationRateTf,
                    hint: "20 x/menit",
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _fieldBebas(
              primaryText: 'Skala Nyeri',
              secondaryText: 'Pain Scale (0-10)',
              controller: kunjunganProv.skalaNyeriTf,
              hint: "0-10",
            ),
          ],
        ),

        const SizedBox(height: 16),

        _buildCollapsibleSection(
          title: "Pemeriksaan Mental",
          icon: Icons.psychology,
          children: [
            _fieldBebas(
              primaryText: 'Deskripsi Umum',
              secondaryText: 'General Description',
              controller: kunjunganProv.deskripsiUmumTf,
              hint: "Masukkan deskripsi umum...",
            ),
            const SizedBox(height: 12),
            _fieldBebas(
              primaryText: 'Kontak Verbal/Non Verbal',
              secondaryText: 'Verbal/Non-Verbal Contact: Relevan/Irrelevan',
              controller: kunjunganProv.kontakTf,
              hint: "Contoh: Relevan / Irrelevan",
            ),
            const SizedBox(height: 12),
            _fieldBebas(
              primaryText: 'Kesadaran',
              secondaryText: 'Consciousness',
              controller: kunjunganProv.kesadaranTf,
              hint: "Masukkan tingkat kesadaran...",
            ),
            const SizedBox(height: 12),
            _fieldBebas(
              primaryText: 'Orientasi Waktu/Tempat/Orang',
              secondaryText: 'Time/Place/Person Orientation',
              controller: kunjunganProv.orientasiTf,
              hint: "Masukkan orientasi...",
            ),
            const SizedBox(height: 12),
            _fieldBebas(
              primaryText: 'Memori/Daya Ingat',
              secondaryText: 'Memory',
              controller: kunjunganProv.memoriTf,
              hint: "Masukkan penilaian memori...",
            ),
            const SizedBox(height: 12),
            _fieldBebas(
              primaryText: 'Konsentrasi/Atensi',
              secondaryText: 'Concentration/Attention',
              controller: kunjunganProv.konsentrasiTf,
              hint: "Masukkan penilaian konsentrasi...",
            ),
            const SizedBox(height: 12),
            _fieldBebas(
              primaryText: 'Mood/Afek',
              secondaryText: 'Mood/Affect',
              controller: kunjunganProv.moodTf,
              hint: "Masukkan mood/afek...",
            ),
            const SizedBox(height: 12),
            _fieldBebas(
              primaryText: 'Proses Berpikir',
              secondaryText: 'Thought Process',
              controller: kunjunganProv.prosesBerpikirTf,
              hint: "Masukkan proses berpikir...",
            ),
            const SizedBox(height: 12),
            _fieldBebas(
              primaryText: 'Persepsi',
              secondaryText: 'Perception',
              controller: kunjunganProv.persepsiTf,
              hint: "Masukkan penilaian persepsi...",
            ),
            const SizedBox(height: 12),
            _fieldBebas(
              primaryText: 'Kemauan',
              secondaryText: 'Volition',
              controller: kunjunganProv.kemauanTf,
              hint: "Masukkan penilaian kemauan...",
            ),
            const SizedBox(height: 12),
            _fieldBebas(
              primaryText: 'Psikomotor',
              secondaryText: 'Psychomotor',
              controller: kunjunganProv.psikomotorTf,
              hint: "Masukkan penilaian psikomotor...",
            ),
            const SizedBox(height: 12),
            _fieldBebas(
              primaryText: 'Intelegensi',
              secondaryText: 'Intelligence',
              controller: kunjunganProv.intelegensiTf,
              hint: "Masukkan penilaian intelegensi...",
            ),
          ],
        ),

        const SizedBox(height: 16),

        _buildCollapsibleSection(
          title: "Diagnosis & Terapi",
          icon: Icons.medication,
          children: [
            _fieldBebas(
              primaryText: 'Diagnosis',
              secondaryText: 'Diagnosis',
              controller: kunjunganProv.diagnosisTf,
              hint: "Masukkan diagnosis...",
            ),
            const SizedBox(height: 12),
            _fieldBebas(
              primaryText: 'Terapi',
              secondaryText: 'Therapy',
              controller: kunjunganProv.terapiTf,
              hint: "Masukkan terapi yang diberikan...",
            ),
            const SizedBox(height: 12),
            _fieldBebas(
              primaryText: 'Catatan',
              secondaryText: 'Notes',
              controller: kunjunganProv.noteTf,
              hint: "Masukkan catatan tambahan...",
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCollapsibleSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: blueHighlight.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: blueDark),
          ),
          title: Text(
            title,
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.bold,
              color: blueDark,
              fontSize: 15,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(children: children),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveKunjungan(
      BuildContext context, KunjunganProvider kunjunganProv) async {
    if (kunjunganProv.keluhanUtamaTf.text.isEmpty ||
        kunjunganProv.tanggalKunjungan == null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return defaultInvalidDialog(
            context: context,
            content: const Text(
                "Mohon isi field Keluhan Utama dan Tanggal Kunjungan!"),
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
            kunjunganProv.selectedKunjungan == null
                ? "Tambahkan kunjungan ini?"
                : "Update data kunjungan ini?",
          ),
        );
      },
    );

    if (confirmed == true) {
      bool success;
      if (kunjunganProv.selectedKunjungan == null) {
        success = await kunjunganProv.addKunjungan(widget.pasienId);
      } else {
        success = await kunjunganProv
            .updateKunjungan(kunjunganProv.createdBy ?? "system");
      }

      if (success && context.mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return defaultSuccessDialog(
              context: context,
              content: Text(
                kunjunganProv.selectedKunjungan == null
                    ? "Kunjungan Berhasil ditambahkan!"
                    : "Data Kunjungan Berhasil diupdate!",
              ),
            );
          },
        ).then((_) {
          setState(() {
            _showKunjunganForm = false;
          });
        });
      } else if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) =>
              defaultErrorDialog(message: kunjunganProv.errorMessage),
        );
      }
    }
  }

  Future<void> _confirmDeleteKunjungan(
      KunjunganModel kunjungan, KunjunganProvider kunjunganProv) async {
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return defaultConfirmationDialog(
          context: context,
          content: Text(
              "Hapus kunjungan tanggal ${DateFormat('dd MMMM yyyy').format(kunjungan.tanggalKunjungan)}?"),
        );
      },
    );

    if (confirmed == true) {
      final success = await kunjunganProv.deleteKunjungan(
          kunjungan.kunjunganId, kunjungan.pasienId);
      // `mounted` milik State, bukan `context.mounted` — di dalam State hanya
      // yang pertama yang menjamin widget masih hidup setelah await.
      if (success && mounted) {
        setState(() {
          _selectedKunjungan = null;
        });
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return defaultSuccessDialog(
              context: context,
              content: const Text("Kunjungan berhasil dihapus!"),
            );
          },
        );
      } else if (mounted) {
        showDialog(
          context: context,
          builder: (context) => defaultErrorDialog(),
        );
      }
    }
  }
}
