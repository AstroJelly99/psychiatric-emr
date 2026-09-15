import 'package:flutter/material.dart';
import 'package:emr_homemade/FBBlock/sk_block.dart';
import 'package:emr_homemade/domain/asesmen_psikologis/asesmen_section_provider.dart';
import 'package:emr_homemade/domain/drug_interaction/drug_interaction_provider.dart';
import 'package:emr_homemade/domain/resep/resep_provider.dart';
import 'package:emr_homemade/presentation/pasien/widgets/detail_pasien_section.dart';
import 'package:emr_homemade/presentation/pasien/widgets/edit_pasien.dart';
import 'package:emr_homemade/presentation/pasien/widgets/kunjungan_section.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:emr_homemade/data/models/pasien_model.dart';
import 'package:emr_homemade/data/repositories/pasien_repo.dart';
import 'package:emr_homemade/domain/pasien/pasien_provider.dart';
import 'package:emr_homemade/domain/kunjungan/kunjungan_provider.dart';
import 'package:emr_homemade/utils/widgets/alert_dialogs.dart';
import 'package:emr_homemade/utils/widgets/constant.dart';

class PasienDetailPage extends StatefulWidget {
  final String pasienId;

  const PasienDetailPage({super.key, required this.pasienId});

  @override
  State<PasienDetailPage> createState() => _PasienDetailPageState();
}

class _PasienDetailPageState extends State<PasienDetailPage> {
  PasienModel? _pasien;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final pasien = await PasienRepo.getById(widget.pasienId);
      setState(() {
        _pasien = pasien;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => KunjunganProvider(context)
            ..loadKunjunganByPasienId(widget.pasienId),
        ),
        ChangeNotifierProvider(
          create: (_) => ResepProvider(context),
        ),
        ChangeNotifierProvider(
          create: (_) => AsesmenSectionProvider(context),
        ),
        ChangeNotifierProvider(
          create: (_) => DrugInteractionProvider(),
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Detail Pasien',
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          backgroundColor: Colors.grey[300],
          iconTheme: const IconThemeData(color: Colors.black),
          elevation: 0.5,
          actions: [
            if (_pasien != null)
              TextButton.icon(
                onPressed: () => _showEditDialog(context),
                icon: const Icon(Icons.edit, color: Colors.black),
                label: Text(
                  "Edit Pasien",
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _pasien == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'Data pasien tidak ditemukan',
                          style: GoogleFonts.nunito(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        DetailPasienSection(pasien: _pasien!),

                        const SizedBox(height: 24),

                        KunjunganSection(
                          pasienId: widget.pasienId,
                          pasien: _pasien,
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context) async {
    final prov = Provider.of<PasienProvider>(context, listen: false);
    prov.setEditForm(_pasien!);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        // defaultDialog (bukan AlertDialog mentah): AlertDialog membungkus
        // isinya dengan IntrinsicWidth, yang bikin LayoutBuilder di dalam
        // lineWrap responsif error.
        return defaultDialog(
          title: "Edit Pasien",
          titleStyle: GoogleFonts.nunito(
            fontWeight: FontWeight.bold,
            color: blueDark,
            fontSize: 20,
          ),
          // 648 = lebar isi 600 + padding dialog 24x2, supaya lebar field di
          // desktop sama seperti sebelum pindah ke defaultDialog.
          maxWidth: 648,
          contents: [
            ChangeNotifierProvider.value(
              value: prov,
              child: Consumer<PasienProvider>(
                builder: (context, provider, _) {
                  return DialogEditPasien(
                      prov: provider, pasienId: widget.pasienId);
                },
              ),
            ),
          ],
          actions: [
            SkBlock.freeButton(
              onTap: () => Navigator.of(context).pop(false),
              color: Colors.grey.shade300,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cancel, color: Colors.black, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    "BATAL",
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            SkBlock.freeButton(
              onTap: () async {
                if (prov.nameTf.text.isEmpty ||
                    prov.addressTf.text.isEmpty ||
                    prov.gender == null ||
                    prov.birthdate == null ||
                    prov.phoneTf.text.isEmpty) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Error"),
                      content:
                          const Text("Mohon isi semua field yang diperlukan!"),
                      actions: [
                        SkBlock.freeButton(
                          onTap: () => Navigator.of(context).pop(),
                          color: blueHighlight,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 14),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check,
                                  color: Colors.black, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                "OKE",
                                style: GoogleFonts.nunito(
                                  color: blackPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                  return;
                }

                bool success =
                    await prov.updatePasien(prov.createdBy ?? "system");
                if (success && context.mounted) {
                  Navigator.of(context).pop(true);
                }
              },
              color: blueHighlight,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.save, color: Colors.black, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    "SIMPAN",
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.bold,
                      color: blackPrimary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );

    // `context.mounted`, bukan `mounted` milik State: context di sini adalah
    // parameter _showEditDialog, yang belum tentu context State ini.
    if (result == true && context.mounted) {
      _loadData();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Sukses"),
          content: const Text("Data Pasien Berhasil diupdate!"),
          actions: [
            SkBlock.freeButton(
              color: blueHighlight,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              onTap: () => Navigator.of(context).pop(),
              child: Text(
                "OKE",
                style: GoogleFonts.nunito(
                  color: blackPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}
