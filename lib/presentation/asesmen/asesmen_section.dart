import 'package:flutter/material.dart';
import 'package:emr_homemade/data/models/asesmen_psikologis_model.dart';
import 'package:emr_homemade/data/models/pasien_model.dart';
import 'package:emr_homemade/FBBlock/sk_block.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:emr_homemade/domain/asesmen_psikologis/asesmen_section_provider.dart';
import 'package:emr_homemade/data/models/kunjungan_model.dart';
import 'package:emr_homemade/utils/widgets/alert_dialogs.dart';
import 'package:intl/intl.dart';

class AsesmenSection extends StatelessWidget {
  final KunjunganModel kunjungan;
  final String pasienId;
  final PasienModel? pasien;

  const AsesmenSection({
    super.key,
    required this.kunjungan,
    required this.pasienId,
    this.pasien,
  });

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AsesmenSectionProvider>(context, listen: false);
      provider.loadAsesmenByKunjunganId(kunjungan.kunjunganId);
      // Seluruh asesmen pasien. Penyaringan "bukan kunjungan ini" dilakukan
      // saat menampilkan, supaya kartu rujukan di form kunjungan bisa memakai
      // daftar yang sama untuk keperluannya sendiri.
      provider.loadRiwayatAsesmen(pasienId);
    });

    return Consumer<AsesmenSectionProvider>(
      builder: (context, asesmenProv, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade50, Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple.shade200),
              ),
              // overflowWrap membungkus sectionHeader (bukan trailing di
              // dalamnya): trailing tidak bisa menyusut, dan ikon berukuran
              // tetap tidak tertolong oleh Flexible pada judulnya saja.
              child: SkBlock.overflowWrap(
                spacing: 12,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SkBlock.sectionHeader(
                    leadingSpacing: 16,
                    title: "Asesmen Psikologis",
                    titleStyle: GoogleFonts.nunito(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple.shade800,
                    ),
                    subtitle:
                        "${asesmenProv.asesmenList.length} Asesmen Tersimpan",
                    subtitleStyle: GoogleFonts.nunito(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade600,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.shade300,
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.psychology,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        _navigateToCreateAsesmen(context, asesmenProv);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.purple.shade600, Colors.purple.shade400],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purple.shade300,
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add_circle, size: 18, color: Colors.white),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                "BUAT ASESMEN",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 13,
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
            ),

            const SizedBox(height: 16),

            // Riwayat kunjungan sebelumnya DI ATAS daftar kunjungan ini —
            // skor lama adalah dasar keputusan menilai lagi, jadi harus
            // kelihatan sebelum ajakan "buat asesmen baru", bukan sesudahnya.
            _buildRiwayatAsesmen(context, asesmenProv),

            const SizedBox(height: 16),

            if (asesmenProv.asesmenList.isNotEmpty)
              ...asesmenProv.asesmenList.map((asesmen) =>
                _AsesmenCard(
                  asesmen: asesmen,
                  asesmenProv: asesmenProv,
                  kunjungan: kunjungan,
                  pasien: pasien,
                )
              )
            else
              _buildEmptyAsesmenState(),

            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  /// Riwayat asesmen dari kunjungan lain, ditampilkan sebagai perbandingan
  /// skor.
  ///
  /// Sengaja TIDAK menyediakan tombol salin, tidak seperti kartu rujukan
  /// kunjungan dan resep. Skor asesmen adalah hasil pengukuran pada satu
  /// waktu; menyalinnya ke asesmen baru berarti mengarang data pemeriksaan,
  /// bukan menghemat pengetikan.
  Widget _buildRiwayatAsesmen(
      BuildContext context, AsesmenSectionProvider prov) {
    if (prov.riwayatLoading) return const SizedBox.shrink();
    // Menyaring di sini, bukan di provider — lihat catatan di
    // AsesmenSectionProvider.loadRiwayatAsesmen.
    final lain = prov.riwayatAsesmen
        .where((a) => a.kunjunganId != kunjungan.kunjunganId)
        .toList();
    if (lain.isEmpty) return const SizedBox.shrink();
    return _RiwayatAsesmenCard(prov: prov, list: lain);
  }

  void _navigateToCreateAsesmen(BuildContext context, AsesmenSectionProvider asesmenProv) {
    asesmenProv.prefillData(
      pasienId: pasienId,
      pasienName: pasien?.patientName ?? '',
      kunjunganId: kunjungan.kunjunganId,
      tanggalKunjungan: kunjungan.tanggalKunjungan,
    );

    _showCreateAsesmenDialog(context, asesmenProv);
  }

  void _showCreateAsesmenDialog(BuildContext context, AsesmenSectionProvider asesmenProv) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return ChangeNotifierProvider.value(
          value: asesmenProv,
          child: _CreateAsesmenDialog(
            asesmenProv: asesmenProv,
            pasienName: pasien?.patientName ?? '',
            tanggalKunjungan: kunjungan.tanggalKunjungan,
          ),
        );
      },
    );
  }

  Widget _buildEmptyAsesmenState() {
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
          Icon(Icons.psychology, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            "Belum ada asesmen psikologis",
            style: GoogleFonts.nunito(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Klik tombol 'Buat Asesmen' untuk menambahkan asesmen psikologis",
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
}

/// Riwayat asesmen dari kunjungan lain, pemilih tanggal berbentuk chip —
/// tinggi tetap berapa pun jumlah asesmennya (pasien kontrol rutin bisa
/// punya puluhan), pola sama dengan kartu rujukan kunjungan dan resep.
/// Stateful karena mengingat chip yang dipilih; [AsesmenSection] stateless.
class _RiwayatAsesmenCard extends StatefulWidget {
  const _RiwayatAsesmenCard({required this.prov, required this.list});

  final AsesmenSectionProvider prov;

  /// Daftar yang sudah disaring oleh pemanggil. Diterima sebagai parameter,
  /// bukan dibaca langsung dari [prov], karena aturan penyaringannya berbeda
  /// per tempat pemakaian.
  final List<AsesmenPsikologisModel> list;

  @override
  State<_RiwayatAsesmenCard> createState() => _RiwayatAsesmenCardState();
}

class _RiwayatAsesmenCardState extends State<_RiwayatAsesmenCard> {
  bool _terbuka = true;
  String? _dipilihId;

  DateTime _tanggal(AsesmenPsikologisModel a) =>
      a.tanggalAsesmen ?? a.createDate;

  AsesmenPsikologisModel _aktif(List<AsesmenPsikologisModel> list) {
    if (_dipilihId == null) return list.first;
    return list.firstWhere(
      (a) => a.asesmenId == _dipilihId,
      orElse: () => list.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = widget.list;
    if (list.isEmpty) return const SizedBox.shrink();

    final aktif = _aktif(list);
    final urutan = list.indexOf(aktif) + 1;

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
            onTap: () => setState(() => _terbuka = !_terbuka),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
              child: SkBlock.sectionHeader(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                leading: Icon(Icons.timeline_rounded,
                    color: Colors.amber.shade800, size: 22),
                leadingSpacing: 10,
                title: "Asesmen lama ($urutan dari ${list.length})",
                titleStyle: GoogleFonts.nunito(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade900,
                ),
                subtitle: DateFormat('EEEE, dd MMMM yyyy', 'id_ID')
                    .format(_tanggal(aktif)),
                subtitleStyle: GoogleFonts.nunito(
                  fontSize: 15,
                  color: Colors.brown.shade700,
                ),
                trailing: Icon(
                  _terbuka ? Icons.expand_less : Icons.expand_more,
                  color: Colors.amber.shade800,
                  size: 26,
                ),
              ),
            ),
          ),
          if (_terbuka) ...[
            const Divider(height: 1),
            if (list.length > 1) _pemilihTanggal(list, aktif),
            if (list.length > 1) const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _baris("Instrumen",
                      widget.prov.getInstrumenName(aktif.instrumenId)),
                  _baris("Interpretasi", aktif.hasilInterpretasi),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade700,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      "Skor ${aktif.skorTotal}",
                      style: GoogleFonts.nunito(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
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

  Widget _baris(String label, String isi) {
    if (isi.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.brown.shade600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            isi,
            style: GoogleFonts.nunito(
              fontSize: 17,
              height: 1.4,
              color: Colors.brown.shade900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pemilihTanggal(
      List<AsesmenPsikologisModel> list, AsesmenPsikologisModel aktif) {
    return SizedBox(
      height: 58,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final a = list[i];
            final bool dipilih = a.asesmenId == aktif.asesmenId;
            return InkWell(
              onTap: () => setState(() => _dipilihId = a.asesmenId),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: dipilih ? Colors.amber.shade700 : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: dipilih
                        ? Colors.amber.shade700
                        : Colors.amber.shade300,
                  ),
                ),
                child: Center(
                  child: Text(
                    DateFormat('dd MMM yyyy', 'id_ID').format(_tanggal(a)),
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight:
                          dipilih ? FontWeight.bold : FontWeight.w600,
                      color:
                          dipilih ? Colors.black : Colors.brown.shade700,
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
}

class _AsesmenCard extends StatelessWidget {
  final AsesmenPsikologisModel asesmen;
  final AsesmenSectionProvider asesmenProv;
  final KunjunganModel kunjungan;
  final PasienModel? pasien;

  const _AsesmenCard({
    required this.asesmen,
    required this.asesmenProv,
    required this.kunjungan,
    required this.pasien,
  });

  @override
  Widget build(BuildContext context) {
    final instrumenName = asesmenProv.getInstrumenName(asesmen.instrumenId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade400, Colors.purple.shade600],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.psychology,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        instrumenName,
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.purple.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        asesmen.tanggalAsesmen != null
                            ? DateFormat('dd MMM yyyy').format(asesmen.tanggalAsesmen!)
                            : '-',
                        style: GoogleFonts.nunito(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.visibility, color: Colors.blue.shade600, size: 22),
                  onPressed: () {
                    _showDetailDialog(context, asesmen, instrumenName, asesmenProv);
                  },
                  tooltip: "Lihat Detail",
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red.shade600, size: 22),
                  onPressed: () => _confirmDeleteAsesmen(
                    context, asesmen, asesmenProv, instrumenName
                  ),
                  tooltip: "Hapus",
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            Divider(color: Colors.grey.shade200),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.score,
                    label: "Skor Total",
                    value: asesmen.skorTotal.toString(),
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.analytics,
                    label: "Interpretasi",
                    value: asesmen.hasilInterpretasi,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkBlock.sectionHeader(
            leading: Icon(icon, size: 16, color: color),
            leadingSpacing: 8,
            title: label,
            titleStyle: GoogleFonts.nunito(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            // Nama instrumen dan interpretasi bisa panjang ("Skala Depresi
            // Beck (BDI-II)"), sementara kotak ini hanya separuh lebar kartu.
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showDetailDialog(
    BuildContext context,
    AsesmenPsikologisModel asesmen,
    String instrumenName,
    AsesmenSectionProvider asesmenProv,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.all(40),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 900, maxHeight: 700),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade600, Colors.purple.shade400],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.psychology, color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Detail Asesmen",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              instrumenName,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(dialogContext),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSummaryInfo(asesmen, pasien?.patientName ?? ''),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                        FutureBuilder<List<Map<String, dynamic>>>(
                          future: asesmenProv.getDetailAsesmen(asesmen.asesmenId),
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
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Text(
                                    "Error: ${snapshot.error}",
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                              );
                            }

                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Text("Tidak ada data item"),
                                ),
                              );
                            }

                            final detailData = snapshot.data!;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Jawaban Kuesioner (${detailData.length} item)",
                                  style: GoogleFonts.nunito(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple.shade800,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ...detailData.map((item) {
                                  final itemAsesmen = item['item_asesmen'];
                                  final instrumenItem = item['instrumen_item'];
                                  
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey.shade200),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                color: Colors.purple.shade600,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  "${instrumenItem.nomerItem}",
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                instrumenItem.pertanyaan,
                                                style: GoogleFonts.nunito(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.green.shade600,
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                "Skor: ${itemAsesmen.skor}",
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (instrumenItem.teksPertanyaan != null &&
                                            instrumenItem.teksPertanyaan!.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            instrumenItem.teksPertanyaan!,
                                            style: GoogleFonts.nunito(
                                              fontSize: 13,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text("TUTUP"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryInfo(AsesmenPsikologisModel asesmen, String pasienName) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade50, Colors.purple.shade100],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  Icons.person,
                  "Pasien",
                  pasienName,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryItem(
                  Icons.calendar_today,
                  "Tanggal",
                  asesmen.tanggalAsesmen != null
                      ? DateFormat('dd MMM yyyy').format(asesmen.tanggalAsesmen!)
                      : '-',
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  Icons.score,
                  "Skor Total",
                  asesmen.skorTotal.toString(),
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryItem(
                  Icons.analytics,
                  "Interpretasi",
                  asesmen.hasilInterpretasi,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(IconData icon, String label, String value, Color color) {
    return Row(
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
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
        ),
      ],
    );
  }

  Future<void> _confirmDeleteAsesmen(
    BuildContext context,
    AsesmenPsikologisModel asesmen,
    AsesmenSectionProvider asesmenProv,
    String instrumenName,
  ) async {
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return defaultConfirmationDialog(
          context: context,
          content: Text("Hapus asesmen $instrumenName?"),
        );
      },
    );

    if (confirmed == true) {
      final success = await asesmenProv.deleteAsesmen(
        asesmen.asesmenId,
        kunjungan.kunjunganId,
      );
      if (success && context.mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return defaultSuccessDialog(
              context: context,
              content: const Text("Asesmen berhasil dihapus!"),
            );
          },
        );
      } else if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => defaultErrorDialog(),
        );
      }
    }
  }
}

class _CreateAsesmenDialog extends StatefulWidget {
  final AsesmenSectionProvider asesmenProv;
  final String pasienName;
  final DateTime tanggalKunjungan;

  const _CreateAsesmenDialog({
    required this.asesmenProv,
    required this.pasienName,
    required this.tanggalKunjungan,
  });

  @override
  State<_CreateAsesmenDialog> createState() => _CreateAsesmenDialogState();
}

class _CreateAsesmenDialogState extends State<_CreateAsesmenDialog> {
  @override
  Widget build(BuildContext context) {
    // Inset dinamis (pola sama dengan defaultDialog): insetPadding tetap 40
    // menghabiskan seperempat lebar di HP.
    final Size screen = MediaQuery.of(context).size;
    final bool narrow = screen.width < SkBlock.compactBreakpoint;
    final double inset = narrow ? 12 : 40;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: inset, vertical: 24),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 1000,
          maxHeight: screen.height * (narrow ? 0.92 : 0.85),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(narrow ? 16 : 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade600, Colors.purple.shade400],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: SkBlock.sectionHeader(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                leading:
                    const Icon(Icons.psychology, color: Colors.white, size: 28),
                title: "Buat Asesmen Psikologis",
                titleStyle: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                subtitle:
                    "${widget.pasienName} - ${DateFormat('dd MMM yyyy').format(widget.tanggalKunjungan)}",
                subtitleStyle: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    widget.asesmenProv.clearForm();
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(narrow ? 14 : 24),
                child: _buildFormContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormContent() {
    return Consumer<AsesmenSectionProvider>(
      builder: (context, prov, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInstrumenDropdown(prov),
            
            if (prov.selectedInstrumenId != null && prov.instrumenItems.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildQuestionnaireSection(prov),
              
              if (prov.skorTotalController.text.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildResultSection(prov),
                const SizedBox(height: 24),
                _buildSubmitButton(prov),
              ],
            ],
          ],
        );
      },
    );
  }

  Widget _buildInstrumenDropdown(AsesmenSectionProvider prov) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkBlock.sectionHeader(
            leading: Icon(Icons.assessment, color: Colors.purple.shade700),
            title: "Pilih Instrumen Asesmen",
            titleStyle: GoogleFonts.nunito(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: Colors.purple.shade800,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonFormField<String>(
              value: prov.selectedInstrumenId,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: InputBorder.none,
              ),
              // Nama instrumen sering panjang ("Skala Depresi Beck (BDI-II)").
              // Tanpa ellipsis, item yang terpilih memaksa lebar dropdown
              // melebihi dialog.
              style: GoogleFonts.nunito(fontSize: 16, color: Colors.black87),
              hint: Text("Pilih Instrumen",
                  style: GoogleFonts.nunito(fontSize: 16)),
              items: prov.instrumenList.map((instrumen) {
                return DropdownMenuItem(
                  value: instrumen.instrumenId,
                  child: Text(
                    instrumen.namaInstrumen,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  prov.setSelectedInstrumen(value);
                }
              },
              isExpanded: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionnaireSection(AsesmenSectionProvider prov) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade50, Colors.blue.shade100],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.quiz, color: Colors.blue.shade700),
              const SizedBox(width: 12),
              Text(
                "Isi Kuesioner (${prov.instrumenItems.length} pertanyaan)",
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.blue.shade800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...prov.instrumenItems.map((item) {
          final options = prov.getSkoringOptions(item.kategoriSkoring);
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.purple.shade400, Colors.purple.shade600],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          "${item.nomerItem}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.pertanyaan,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
                if (item.teksPertanyaan.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    item.teksPertanyaan,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: options.map((score) {
                    final isSelected = prov.skorControllers[item.instrumenItemId]?.text == score.toString();
                    return InkWell(
                      onTap: () {
                        prov.setSkor(item.instrumenItemId, score);
                      },
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: isSelected 
                            ? LinearGradient(
                                colors: [Colors.purple.shade400, Colors.purple.shade600],
                              )
                            : null,
                          color: isSelected ? null : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? Colors.purple.shade600 : Colors.grey[300]!,
                            width: 2,
                          ),
                          boxShadow: isSelected ? [
                            BoxShadow(
                              color: Colors.purple.shade300,
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ] : null,
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
                if (prov.skorControllers[item.instrumenItemId]?.text.isNotEmpty == true)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            "Skor terpilih: ${prov.skorControllers[item.instrumenItemId]!.text}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildResultSection(AsesmenSectionProvider prov) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade50, Colors.purple.shade100],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.purple.shade700, size: 28),
              const SizedBox(width: 12),
              Text(
                "Hasil Asesmen",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.purple.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildResultCard(
                  "Skor Total",
                  prov.skorTotalController.text,
                  Icons.score,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildResultCard(
                  "Interpretasi",
                  prov.hasilInterpretasiController.text,
                  Icons.psychology,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(String label, String value, IconData icon, Color color) {
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
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(AsesmenSectionProvider prov) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: prov.isLoading
            ? null
            : () async {
                final success = await prov.submitAsesmen();
                // `mounted` milik State, bukan `context.mounted`: di dalam
                // State keduanya tidak setara dan hanya yang pertama yang
                // benar-benar menjamin widget masih hidup setelah await.
                if (success && mounted) {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) => defaultSuccessDialog(
                      context: context,
                      content: const Text("Asesmen berhasil disimpan!"),
                    ),
                  );
                } else if (mounted) {
                  showDialog(
                    context: context,
                    builder: (context) => defaultErrorDialog(),
                  );
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.purple.shade600,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: prov.isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.save, color: Colors.white),
                  SizedBox(width: 12),
                  Text(
                    "SIMPAN ASESMEN",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

}