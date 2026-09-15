import 'dart:async';

import 'package:flutter/material.dart';
import 'package:emr_homemade/FBBlock/sk_block.dart';
import 'package:emr_homemade/data/models/pasien_model.dart';
import 'package:provider/provider.dart';
import 'package:emr_homemade/domain/pasien/pasien_provider.dart';
import 'package:emr_homemade/utils/widgets/alert_dialogs.dart';
import 'package:emr_homemade/utils/widgets/loading_widgets.dart';
import 'package:emr_homemade/presentation/pasien/pasien_detail.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:emr_homemade/utils/widgets/constant.dart';

class ManagePasienPage extends StatefulWidget {
  const ManagePasienPage({super.key});

  @override
  State<ManagePasienPage> createState() => _ManagePasienPageState();
}

class _ManagePasienPageState extends State<ManagePasienPage> {
  final TextEditingController _searchController = TextEditingController();

  // Jeda sebelum query jalan. Tanpa ini tiap huruf yang diketik langsung
  // jadi 1 request ke server — ketik "budi" = 4 request beruntun, boros dan
  // hasil yang datang belakangan bisa menimpa hasil yang lebih baru.
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PasienProvider>(context, listen: false).loadPasiens();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value, PasienProvider prov) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (value.isEmpty) {
        prov.loadPasiens();
      } else {
        prov.searchByName(value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PasienProvider>(
      builder: (context, prov, _) {
        return Scaffold(
          backgroundColor: Colors.grey.shade100,
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // lineWrap: tombol lebar tetap bikin judul overflow di layar
                // sempit; ini menumpuknya dan melebarkan tombol penuh.
                SkBlock.lineWrap(
                  responsive: true,
                  spacing: 12,
                  children: [
                    SkBlock.lineBlock(
                      text: "Manajemen Pasien",
                      isHeader: true,
                      padding: const EdgeInsets.all(15),
                    ),
                    Material(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          _showCreatePasienDialog(context, prov);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: blueHighlight,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.person_add,
                                color: Colors.black,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  "TAMBAH PASIEN",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.nunito(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                    fontSize: 14,
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
                const SizedBox(height: 10),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      )
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Cari pasien...",
                      hintStyle: GoogleFonts.nunito(),
                      border: InputBorder.none,
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _debounce?.cancel();
                                _searchController.clear();
                                setState(() {});
                                prov.loadPasiens();
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      // setState di sini cuma buat memunculkan/menyembunyikan
                      // tombol clear (X) seketika — query yang sebenarnya
                      // tetap lewat _onSearchChanged yang ditunda.
                      setState(() {});
                      _onSearchChanged(value, prov);
                    },
                  ),
                ),
                const SizedBox(height: 20),
                
                Expanded(
                  child: prov.errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline,
                                  size: 48, color: Colors.red.shade400),
                              const SizedBox(height: 12),
                              Text(
                                'Error: ${prov.errorMessage}',
                                style: GoogleFonts.nunito(color: Colors.red),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () => prov.loadPasiens(),
                                icon: const Icon(Icons.refresh),
                                label: Text("Coba Lagi",
                                    style: GoogleFonts.nunito()),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                ),
                              )
                            ],
                          ),
                        )
                      : prov.isLoading
                          ? _skeletonPatientList()
                          : prov.filteredPasiens.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.person_off,
                                          size: 60,
                                          color: Colors.grey.shade400),
                                      const SizedBox(height: 10),
                                      Text(
                                        "Tidak ada data pasien",
                                        style: GoogleFonts.nunito(
                                            color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                )
                              : RefreshIndicator(
                                  onRefresh: () async {
                                    await prov.loadPasiens();
                                  },
                                  // Grid persegi (childAspectRatio 1.1) sisakan
                                  // banyak ruang kosong di layar sempit; pakai
                                  // daftar biasa di sana.
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      final bool compact =
                                          constraints.maxWidth.isFinite &&
                                              constraints.maxWidth <
                                                  SkBlock.compactBreakpoint;

                                      if (compact) {
                                        return ListView.separated(
                                          itemCount:
                                              prov.filteredPasiens.length,
                                          separatorBuilder: (_, __) =>
                                              const SizedBox(height: 12),
                                          itemBuilder: (context, index) =>
                                              _buildPatientCard(
                                            prov.filteredPasiens[index],
                                            context,
                                            prov,
                                            compact: true,
                                          ),
                                        );
                                      }

                                      return GridView.builder(
                                        gridDelegate:
                                            const SliverGridDelegateWithMaxCrossAxisExtent(
                                          maxCrossAxisExtent: 380,
                                          crossAxisSpacing: 16,
                                          mainAxisSpacing: 16,
                                          childAspectRatio: 1.1,
                                        ),
                                        itemCount:
                                            prov.filteredPasiens.length,
                                        itemBuilder: (context, index) =>
                                            _buildPatientCard(
                                          prov.filteredPasiens[index],
                                          context,
                                          prov,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCreatePasienDialog(BuildContext context, PasienProvider prov) {
    prov.clearForm();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (stfContext, setDialogState) {
            prov.addListener(() {
              setDialogState(() {});
            });

            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              prov.existingPasienId == null
                                  ? "Tambah Pasien Baru"
                                  : "Edit Data Pasien",
                              style: GoogleFonts.nunito(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.of(dialogContext).pop(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        _buildTextField(
                          label: 'Nama Pasien',
                          hint: "Masukkan Nama Pasien",
                          controller: prov.nameTf,
                          onChanged: () => setDialogState(() {}),
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                          label: 'Alamat',
                          hint: "Masukkan Alamat Pasien",
                          controller: prov.addressTf,
                          onChanged: () => setDialogState(() {}),
                        ),
                        const SizedBox(height: 16),

                        _buildGenderDropdown(prov, setDialogState),
                        const SizedBox(height: 16),

                        _buildDatePicker(stfContext, prov, setDialogState),
                        const SizedBox(height: 16),

                        _buildTextField(
                          label: 'Nomor Telepon',
                          // Boleh lebih dari satu nomor, satu baris per
                          // nomor — pasien dan keluarganya sering punya
                          // nomor berbeda-beda.
                          hint: "0812xxxx (Pasien)\n0813xxxx (Ayah)",
                          controller: prov.phoneTf,
                          maxLines: 3,
                          onChanged: () => setDialogState(() {}),
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                          label: 'Alergi',
                          hint: "Masukkan Alergi (jika ada)",
                          controller: prov.allergyTf,
                          onChanged: () => setDialogState(() {}),
                        ),
                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          child: Material(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () async {
                                if (prov.nameTf.text.isEmpty ||
                                    prov.addressTf.text.isEmpty ||
                                    prov.gender == null ||
                                    prov.birthdate == null ||
                                    prov.phoneTf.text.isEmpty) {
                                  showDialog(
                                    context: dialogContext,
                                    builder: (BuildContext ctx) {
                                      return defaultInvalidDialog(
                                        context: ctx,
                                        title: const Text("Field Kosong!"),
                                        content: const Text(
                                            "Mohon isi semua field yang diperlukan!"),
                                      );
                                    },
                                  );
                                  return;
                                }

                                bool? confirmed = await showDialog<bool>(
                                  context: dialogContext,
                                  builder: (BuildContext ctx) {
                                    return defaultConfirmationDialog(
                                      context: ctx,
                                      content: Text(
                                        prov.existingPasienId == null
                                            ? "Tambahkan pasien ini?"
                                            : "Update data pasien ini?",
                                      ),
                                    );
                                  },
                                );

                                if (confirmed == true) {
                                  bool success;
                                  if (prov.existingPasienId == null) {
                                    success = await prov.addPasien();
                                  } else {
                                    success = await prov.updatePasien(
                                        prov.createdBy ?? "system");
                                  }

                                  if (success && dialogContext.mounted) {
                                    Navigator.of(dialogContext).pop();
                                    if (context.mounted) {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext ctx) {
                                          return defaultSuccessDialog(
                                            context: ctx,
                                            content: Text(
                                              prov.existingPasienId == null
                                                  ? "Pasien Berhasil ditambahkan!"
                                                  : "Data Pasien Berhasil diupdate!",
                                            ),
                                          );
                                        },
                                      );
                                    }
                                  } else if (dialogContext.mounted) {
                                    showDialog(
                                      context: dialogContext,
                                      builder: (ctx) => defaultErrorDialog(),
                                    );
                                  }
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: blueHighlight,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      prov.existingPasienId == null
                                          ? Icons.person_add
                                          : Icons.update,
                                      color: Colors.black,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      prov.existingPasienId == null
                                          ? "TAMBAH PASIEN"
                                          : "UPDATE PASIEN",
                                      style: GoogleFonts.nunito(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType? keyboardType,
    VoidCallback? onChanged,
    int? maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          onChanged: (_) => onChanged?.call(),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.nunito(color: Colors.grey.shade400),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: blueHighlight, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderDropdown(PasienProvider prov, StateSetter setState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Jenis Kelamin',
          style: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(8),
              isExpanded: true,
              hint: Text(
                'Pilih Jenis Kelamin',
                style: GoogleFonts.nunito(color: Colors.grey.shade400),
              ),
              value: prov.gender,
              items: const [
                DropdownMenuItem<String>(
                  value: 'L',
                  child: Text('Laki-laki'),
                ),
                DropdownMenuItem<String>(
                  value: 'P',
                  child: Text('Perempuan'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  prov.gender = value;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker(BuildContext context, PasienProvider prov, StateSetter setState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tanggal Lahir',
          style: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final selectedDate = await showDatePicker(
              context: context,
              initialDate: prov.birthdate ?? DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
            );
            if (selectedDate != null) {
              setState(() {
                prov.birthdate = selectedDate;
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  prov.birthdate != null
                      ? DateFormat('dd MMMM yyyy').format(prov.birthdate!)
                      : "Pilih Tanggal Lahir",
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    color: prov.birthdate != null
                        ? Colors.black
                        : Colors.grey.shade400,
                  ),
                ),
                const Icon(Icons.calendar_today, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// [compact] true saat kartu dipakai di daftar bertinggi bebas (HP).
  /// Di sana `Spacer()` tidak boleh dipakai: tinggi Column-nya tak terbatas,
  /// dan anak ber-flex di dalam tinggi tak terbatas adalah error, bukan
  /// sekadar tampilan yang meleset.
  /// Ganti [CircularProgressIndicator] polos saat memuat daftar pasien.
  /// Bentuknya meniru [_buildPatientCard] — supaya begitu data betulan
  /// datang, tidak ada "lompatan" tata letak dari spinner-di-tengah ke
  /// daftar kartu.
  Widget _skeletonPatientList({int count = 5}) {
    return SkeletonPulse(
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(radius: 24, backgroundColor: Colors.grey.shade300),
                  const SizedBox(width: 12),
                  Expanded(child: skeletonBox(height: 18)),
                ],
              ),
              const SizedBox(height: 12),
              skeletonBox(width: 140),
              const SizedBox(height: 6),
              skeletonBox(width: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatientCard(
      PasienModel pasien, BuildContext context, PasienProvider prov,
      {bool compact = false}) {
    return InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChangeNotifierProvider.value(
                value: prov,
                child: PasienDetailPage(pasienId: pasien.pasienId),
              ),
            ),
          ).then((_) => _refreshData());
        },
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: pasien.patientGender == "L"
                        ? Colors.blue.shade50
                        : Colors.pink.shade50,
                    child: Icon(
                      pasien.patientGender == "L" ? Icons.male : Icons.female,
                      size: 26,
                      color: pasien.patientGender == "L"
                          ? Colors.blue.shade600
                          : Colors.pink.shade400,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      pasien.patientName,
                      style: GoogleFonts.nunito(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                ],
              ),
              const SizedBox(height: 12),

              Text(
                "Usia: ${_calculateAge(pasien.patientBirthdate)} tahun",
                style: GoogleFonts.nunito(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.phone, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      pasien.patientPhone,
                      style: GoogleFonts.nunito(color: Colors.grey.shade700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_on,
                      size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      pasien.patientAddress,
                      style: GoogleFonts.nunito(color: Colors.grey.shade700),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (compact) const SizedBox(height: 16) else const Spacer(),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChangeNotifierProvider.value(
                              value: prov,
                              child:
                                  PasienDetailPage(pasienId: pasien.pasienId),
                            ),
                          ),
                        ).then((_) => _refreshData());
                      },
                      icon: const Icon(Icons.visibility, size: 18),
                      label: const Text("Detail"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo.shade500,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        bool? confirmed = await showDialog<bool>(
                          context: context,
                          builder: (BuildContext context) {
                            return defaultConfirmationDialog(
                              context: context,
                              content:
                                  Text("Hapus pasien ${pasien.patientName}?"),
                            );
                          },
                        );

                        if (confirmed == true) {
                          final success = await prov.deletePasien(
                              pasien.pasienId, prov.createdBy ?? "system");
                          if (success && context.mounted) {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return defaultSuccessDialog(
                                  context: context,
                                  content:
                                      const Text("Pasien berhasil dihapus!"),
                                  onFinish: () {},
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
                      },
                      icon: const Icon(Icons.delete, size: 18),
                      label: const Text("Hapus"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ));
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

  void _refreshData() {
    context.read<PasienProvider>().loadPasiens();
  }
}