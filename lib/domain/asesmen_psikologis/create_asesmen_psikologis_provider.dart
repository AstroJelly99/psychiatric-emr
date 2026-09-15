import 'package:flutter/material.dart';
import 'package:emr_homemade/data/models/kunjungan_model.dart';
import 'package:emr_homemade/data/models/pasien_model.dart';
import 'package:emr_homemade/data/repositories/interpretation_rule_repo.dart';
import 'package:emr_homemade/data/repositories/kunjungan_repo.dart';
import 'package:emr_homemade/data/repositories/pasien_repo.dart';
import 'package:emr_homemade/domain/asesmen_psikologis/manage_asesmen_psikologis_provider.dart';
import 'package:emr_homemade/utils/widgets/alert_dialogs.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:emr_homemade/data/models/asesmen_psikologis_model.dart';
import 'package:emr_homemade/data/models/item_asesmen_psikologis_model.dart';
import 'package:emr_homemade/data/models/instrumen_model.dart';
import 'package:emr_homemade/data/models/instrumen_item_model.dart';
import 'package:emr_homemade/data/repositories/asesmen_psikologis_repo.dart';
import 'package:emr_homemade/data/repositories/item_asesmen_psikologis_repo.dart';
import 'package:emr_homemade/data/repositories/instrumen_repo.dart';
import 'package:emr_homemade/data/repositories/instrumen_item_repo.dart';

class CreateAsesmenPsikologisProvider with ChangeNotifier {
  CreateAsesmenPsikologisProvider(this.context) {
    loadPreferences();
    loadInitialData();
  }

  final BuildContext context;

  bool isLoading = false;
  String? errorMessage;

  List<PasienModel> pasienList = [];
  List<PasienModel> filteredPasienList = [];
  List<KunjunganModel> kunjunganList = [];
  List<KunjunganModel> filteredKunjunganList = [];
  List<InstrumenModel> instrumenList = [];
  List<InstrumenModel> filteredInstrumenList = [];
  List<InstrumenItemModel> instrumenItems = [];

  TextEditingController pasienSearchController = TextEditingController();
  TextEditingController kunjunganSearchController = TextEditingController();
  TextEditingController instrumenSearchController = TextEditingController();

  String? selectedPasienId;
  String? selectedKunjunganId;
  String? selectedInstrumenId;

  Map<String, TextEditingController> skorControllers = {};
  TextEditingController skorTotalController = TextEditingController();
  TextEditingController hasilInterpretasiController = TextEditingController();

  String? createdBy;

  Future<void> refreshData() async {
    await loadInitialData();
  }

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    createdBy = prefs.getString('username') ?? 'system';
    notifyListeners();
  }

  Future<void> loadInitialData() async {
    _setLoading(true);
    try {
      pasienList = await PasienRepo.getAll();
      filteredPasienList = List.from(pasienList);

      instrumenList = await InstrumenRepo.getAll();
      filteredInstrumenList = List.from(instrumenList);

      errorMessage = null;
    } catch (e) {
      errorMessage = "Gagal memuat data awal: $e";
    }
    _setLoading(false);
  }

  void filterPasien(String query) {
    if (query.isEmpty) {
      filteredPasienList = List.from(pasienList);
    } else {
      filteredPasienList = pasienList
          .where((pasien) =>
              pasien.patientName.toLowerCase().contains(query.toLowerCase()) ||
              pasien.patientPhone.contains(query))
          .toList();
    }
    notifyListeners();
  }

  void filterKunjungan(String query) {
    if (query.isEmpty) {
      filteredKunjunganList = List.from(kunjunganList);
    } else {
      filteredKunjunganList = kunjunganList
          .where((kunjungan) =>
              kunjungan.tanggalKunjungan.toString().contains(query) ||
              kunjungan.keluhanUtama
                  .toLowerCase()
                  .contains(query.toLowerCase()))
          .toList();
    }
    notifyListeners();
  }

  void filterInstrumen(String query) {
    if (query.isEmpty) {
      filteredInstrumenList = List.from(instrumenList);
    } else {
      filteredInstrumenList = instrumenList
          .where((instrumen) => instrumen.namaInstrumen
              .toLowerCase()
              .contains(query.toLowerCase()))
          .toList();
    }
    notifyListeners();
  }

  Future<void> loadKunjunganByPasien(String pasienId) async {
    _setLoading(true);
    try {
      kunjunganList = await KunjunganRepo.getByPasienId(pasienId);
      filteredKunjunganList = List.from(kunjunganList);
      selectedKunjunganId = null;
      kunjunganSearchController.clear();
      errorMessage = null;
    } catch (e) {
      errorMessage = "Gagal memuat data kunjungan: $e";
    }
    _setLoading(false);
  }

  Future<void> loadInstrumenItems(String instrumenId) async {
    _setLoading(true);
    try {
      instrumenItems = await InstrumenItemRepo.getByInstrumenId(instrumenId);

      for (var controller in skorControllers.values) {
        controller.dispose();
      }
      skorControllers.clear();

      for (var item in instrumenItems) {
        skorControllers[item.instrumenItemId] = TextEditingController();
      }

      skorTotalController.clear();
      hasilInterpretasiController.clear();

      errorMessage = null;
    } catch (e) {
      errorMessage = "Gagal memuat item instrumen: $e";
    }
    _setLoading(false);
  }

  void validateAndCalculateSkor(String itemId, String value) {
    if (value.isNotEmpty) {
      final skor = int.tryParse(value);
      final item = instrumenItems
          .firstWhere((element) => element.instrumenItemId == itemId);
      final options = getSkoringOptions(item.kategoriSkoring);

      if (skor != null && !options.contains(skor)) {
        errorMessage =
            "Skor untuk item ${item.nomerItem} harus antara ${options.first} hingga ${options.last}";
        notifyListeners();
        return;
      }
    }

    calculateTotalSkor();
  }

  List<int> getSkoringOptions(String kategoriSkoring) {
    try {
      final range = kategoriSkoring.split('-');
      if (range.length != 2) return [0, 1, 2, 3, 4];

      final start = int.tryParse(range[0]) ?? 0;
      final end = int.tryParse(range[1]) ?? 4;

      return List.generate(end - start + 1, (index) => start + index);
    } catch (e) {
      return [0, 1, 2, 3, 4]; // fallback
    }
  }

  void calculateTotalSkor() async {
    try {
      int total = 0;
      bool allFilled = true;

      for (var item in instrumenItems) {
        final controller = skorControllers[item.instrumenItemId];
        if (controller != null && controller.text.isNotEmpty) {
          total += int.parse(controller.text);
        } else {
          allFilled = false;
        }
      }

      if (allFilled) {
        skorTotalController.text = total.toString();

        hasilInterpretasiController.text =
            await _getInterpretation(selectedInstrumenId!, total);
      } else {
        skorTotalController.clear();
        hasilInterpretasiController.clear();
      }

      notifyListeners();
    } catch (e) {
      debugPrint("Error calculating total score: $e");
    }
  }

  Future<String> _getInterpretation(String instrumenId, int totalScore) async {
    try {
      return await InterpretationRuleRepo.getInterpretation(
          instrumenId, totalScore);
    } catch (e) {
      debugPrint("Error getting interpretation: $e");
      // Fallback ke default
      if (totalScore >= 20) return "Tinggi";
      if (totalScore >= 10) return "Sedang";
      return "Rendah";
    }
  }

  bool get formValid {
    if (selectedPasienId == null ||
        selectedKunjunganId == null ||
        selectedInstrumenId == null) {
      return false;
    }

    for (var item in instrumenItems) {
      final controller = skorControllers[item.instrumenItemId];
      if (controller == null || controller.text.isEmpty) {
        return false;
      }
    }

    return true;
  }

  Future<bool> submitAsesmen() async {
    if (!formValid) return false;

    _setLoading(true);
    try {
      final selectedInstrumen = instrumenList.firstWhere(
        (i) => i.instrumenId == selectedInstrumenId,
      );

      final selectedKunjungan = kunjunganList.firstWhere(
        (k) => k.kunjunganId == selectedKunjunganId,
      );

      final asesmen = AsesmenPsikologisModel(
        jenisAsesmen: selectedInstrumen.namaInstrumen,
        skorTotal: int.parse(skorTotalController.text),
        hasilInterpretasi: hasilInterpretasiController.text,
        pasienId: selectedPasienId!,
        kunjunganId: selectedKunjunganId!,
        instrumenId: selectedInstrumenId!,
        tanggalAsesmen: selectedKunjungan.tanggalKunjungan,
        isActive: true,
        createdBy: createdBy!,
      );

      await AsesmenPsikologisRepo.insert(asesmen);

      for (var item in instrumenItems) {
        final controller = skorControllers[item.instrumenItemId]!;
        final itemAsesmen = ItemAsesmenPsikologisModel(
          skor: int.parse(controller.text),
          asesmenId: asesmen.asesmenId,
          instrumenItemId: item.instrumenItemId,
          isActive: true,
          createdBy: createdBy!,
        );

        await ItemAsesmenPsikologisRepo.insert(itemAsesmen);
      }

      return true;
    } catch (e) {
      errorMessage = "Gagal menyimpan asesmen: $e";
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void clearForm() {
    selectedPasienId = null;
    selectedKunjunganId = null;
    selectedInstrumenId = null;

    pasienSearchController.clear();
    kunjunganSearchController.clear();
    instrumenSearchController.clear();

    for (var controller in skorControllers.values) {
      controller.dispose();
    }
    skorControllers.clear();

    skorTotalController.clear();
    hasilInterpretasiController.clear();

    instrumenItems.clear();
    kunjunganList.clear();
    filteredKunjunganList.clear();

    filteredPasienList = List.from(pasienList);
    filteredInstrumenList = List.from(instrumenList);

    errorMessage = null;

    notifyListeners();
  }

  /// Memberi tahu widget bahwa field yang di-set langsung dari UI
  /// (selectedInstrumenId, selectedKunjunganId, instrumenItems) sudah berubah.
  ///
  /// Sebelumnya widget memanggil `prov.notifyListeners()` sendiri, padahal
  /// method itu `@protected` — hanya boleh dipanggil dari dalam provider.
  void refreshUi() => notifyListeners();

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  Future<void> handleSubmit(BuildContext context) async {
    if (!formValid) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return defaultInvalidDialog(
            context: context,
            content: const Text(
                "Harap lengkapi semua field yang diperlukan dan isi semua pertanyaan."),
          );
        },
      );
      return;
    }

    bool? userConfirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return defaultConfirmationDialog(
          content: const Text("Simpan asesmen psikologis ini?"),
          context: context,
        );
      },
    );

    if (userConfirmed == true) {
      final success = await submitAsesmen();
      if (success && context.mounted) {
        clearForm(); // sebelum dialog sukses tampil, bukan sesudah
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) {
            return defaultSuccessDialog(
              context: dialogContext,
              content: const Text("Asesmen Psikologis Berhasil disimpan!"),
              onFinish: () {
                if (context.mounted) {
                  context.read<ManageAsesmenPsikologisProvider>().refreshData();
                }
                Navigator.of(dialogContext).pop();
              },
            );
          },
        );
      } else if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) {
            return defaultErrorDialog();
          },
        );
      }
    }
  }

  @override
  void dispose() {
    pasienSearchController.dispose();
    kunjunganSearchController.dispose();
    instrumenSearchController.dispose();

    for (var controller in skorControllers.values) {
      controller.dispose();
    }

    skorTotalController.dispose();
    hasilInterpretasiController.dispose();

    super.dispose();
  }
}
