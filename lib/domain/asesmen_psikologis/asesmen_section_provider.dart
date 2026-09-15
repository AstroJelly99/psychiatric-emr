import 'package:flutter/material.dart';
import 'package:emr_homemade/data/models/asesmen_psikologis_model.dart';
import 'package:emr_homemade/data/models/instrumen_item_model.dart';
import 'package:emr_homemade/data/models/instrumen_model.dart';
import 'package:emr_homemade/data/models/item_asesmen_psikologis_model.dart';
import 'package:emr_homemade/data/repositories/asesmen_psikologis_repo.dart';
import 'package:emr_homemade/data/repositories/instrumen_item_repo.dart';
import 'package:emr_homemade/data/repositories/instrumen_repo.dart';
import 'package:emr_homemade/data/repositories/interpretation_rule_repo.dart';
import 'package:emr_homemade/data/repositories/item_asesmen_psikologis_repo.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AsesmenSectionProvider with ChangeNotifier {
  AsesmenSectionProvider(this.context) {
    loadPreferences();
    loadInstrumen();
  }

  final BuildContext context;

  bool isLoading = false;
  String? errorMessage;
  String? createdBy;

  List<AsesmenPsikologisModel> asesmenList = [];
  List<InstrumenModel> instrumenList = [];
  List<InstrumenItemModel> instrumenItems = [];

  String? prefilledPasienId;
  String? prefilledPasienName;
  String? prefilledKunjunganId;
  DateTime? prefilledTanggalKunjungan;

  String? selectedInstrumenId;

  Map<String, TextEditingController> skorControllers = {};
  TextEditingController skorTotalController = TextEditingController();
  TextEditingController hasilInterpretasiController = TextEditingController();

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    createdBy = prefs.getString('username') ?? 'system';
    notifyListeners();
  }

  Future<void> loadInstrumen() async {
    try {
      instrumenList = await InstrumenRepo.getAll();
      notifyListeners();
    } catch (e) {
      errorMessage = "Gagal memuat instrumen: $e";
      notifyListeners();
    }
  }

  Future<void> loadAsesmenByKunjunganId(String kunjunganId) async {
    _setLoading(true);
    try {
      final allAsesmen = await AsesmenPsikologisRepo.getAll();
      asesmenList = allAsesmen
          .where((asesmen) => asesmen.kunjunganId == kunjunganId)
          .toList();

      errorMessage = null;
    } catch (e) {
      errorMessage = "Gagal memuat asesmen: $e";
    }
    _setLoading(false);
  }

  /// Asesmen dari SELURUH kunjungan pasien ini, terbaru lebih dulu.
  ///
  /// Terpisah dari [asesmenList] dengan sengaja: [asesmenList] hanya berisi
  /// asesmen pada kunjungan yang sedang dibuka. Riwayat di bawah ini murni
  /// rujukan — dokter membacanya untuk melihat perkembangan skor sebelum
  /// menilai lagi, dan itu tidak masuk akal kalau hanya bisa melihat asesmen
  /// pada kunjungan yang sama.
  List<AsesmenPsikologisModel> riwayatAsesmen = [];
  bool riwayatLoading = false;

  /// Memuat SELURUH asesmen pasien tanpa menyaring apa pun.
  ///
  /// Penyaringan diserahkan ke widget dengan alasan yang sama seperti pada
  /// riwayat resep: form asesmen ingin membuang kunjungan yang sedang dibuka,
  /// sedangkan kartu rujukan di form kunjungan ingin asesmen milik satu
  /// kunjungan lama tertentu. Menyaring di sini membuat keduanya berebut isi
  /// daftar yang sama.
  Future<void> loadRiwayatAsesmen(String pasienId) async {
    riwayatLoading = true;
    notifyListeners();
    try {
      riwayatAsesmen = await AsesmenPsikologisRepo.getByPasienId(pasienId)
        ..sort((a, b) {
          final ta = a.tanggalAsesmen ?? a.createDate;
          final tb = b.tanggalAsesmen ?? b.createDate;
          return tb.compareTo(ta);
        });
    } catch (e) {
      riwayatAsesmen = [];
      errorMessage = "Gagal memuat riwayat asesmen: $e";
    }
    riwayatLoading = false;
    notifyListeners();
  }

  void prefillData({
    required String pasienId,
    required String pasienName,
    required String kunjunganId,
    required DateTime tanggalKunjungan,
  }) {
    prefilledPasienId = pasienId;
    prefilledPasienName = pasienName;
    prefilledKunjunganId = kunjunganId;
    prefilledTanggalKunjungan = tanggalKunjungan;
    notifyListeners();
  }

  void setSelectedInstrumen(String instrumenId) async {
    selectedInstrumenId = instrumenId;
    notifyListeners();

    await loadInstrumenItems(instrumenId);
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

  List<int> getSkoringOptions(String kategoriSkoring) {
    try {
      final range = kategoriSkoring.split('-');
      if (range.length != 2) return [0, 1, 2, 3, 4];

      final start = int.tryParse(range[0]) ?? 0;
      final end = int.tryParse(range[1]) ?? 4;

      return List.generate(end - start + 1, (index) => start + index);
    } catch (e) {
      return [0, 1, 2, 3, 4];
    }
  }

  void setSkor(String itemId, int skor) {
    skorControllers[itemId]?.text = skor.toString();
    calculateTotalSkor();
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

  Future<bool> submitAsesmen() async {
    if (prefilledPasienId == null ||
        prefilledKunjunganId == null ||
        selectedInstrumenId == null) {
      return false;
    }

    _setLoading(true);
    try {
      final selectedInstrumen = instrumenList.firstWhere(
        (i) => i.instrumenId == selectedInstrumenId,
      );

      final asesmen = AsesmenPsikologisModel(
        jenisAsesmen: selectedInstrumen.namaInstrumen,
        skorTotal: int.parse(skorTotalController.text),
        hasilInterpretasi: hasilInterpretasiController.text,
        pasienId: prefilledPasienId!,
        kunjunganId: prefilledKunjunganId!,
        instrumenId: selectedInstrumenId!,
        tanggalAsesmen: prefilledTanggalKunjungan ?? DateTime.now(),
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

      await loadAsesmenByKunjunganId(prefilledKunjunganId!);
      // Riwayat ikut dimuat ulang. Tanpa ini, kartu rujukan di form kunjungan
      // baru masih memakai riwayat yang dimuat saat KunjunganSection pertama
      // kali dipasang — widget itu tidak pernah dibangun ulang saat dokter
      // masuk ke detail kunjungan lalu kembali, jadi asesmen yang baru saja
      // diisi tidak akan pernah muncul di sana.
      await loadRiwayatAsesmen(prefilledPasienId!);

      clearForm();
      return true;
    } catch (e) {
      errorMessage = "Gagal menyimpan asesmen: $e";
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteAsesmen(String asesmenId, String kunjunganId) async {
    try {
      // Dicari sebelum dihapus — sesudahnya asesmen ini sudah lenyap dari
      // kedua daftar dan pasienId-nya tidak bisa ditemukan lagi.
      final pasienId = _cariPasienId(asesmenId);
      await AsesmenPsikologisRepo.delete(asesmenId, createdBy ?? "system");
      await loadAsesmenByKunjunganId(kunjunganId);
      if (pasienId != null) await loadRiwayatAsesmen(pasienId);
      return true;
    } catch (e) {
      errorMessage = "Gagal menghapus asesmen: $e";
      notifyListeners();
      return false;
    }
  }

  /// Pasien pemilik sebuah asesmen, dicari dari daftar yang sudah di memori.
  /// Alasannya sama seperti pada resep: `deleteAsesmen` tidak menerima
  /// pasienId, sedangkan riwayat disusun per pasien.
  String? _cariPasienId(String asesmenId) {
    for (final daftar in [asesmenList, riwayatAsesmen]) {
      for (final a in daftar) {
        if (a.asesmenId == asesmenId) return a.pasienId;
      }
    }
    return null;
  }

  String getInstrumenName(String instrumenId) {
    try {
      return instrumenList
          .firstWhere((i) => i.instrumenId == instrumenId)
          .namaInstrumen;
    } catch (e) {
      return 'Unknown';
    }
  }

  Future<List<Map<String, dynamic>>> getDetailAsesmen(String asesmenId) async {
    try {
      final itemAsesmenList =
          await ItemAsesmenPsikologisRepo.getByAsesmenId(asesmenId);

      if (itemAsesmenList.isEmpty) {
        return [];
      }

      final instrumenItemIds =
          itemAsesmenList.map((item) => item.instrumenItemId).toList();

      final List<Future<InstrumenItemModel?>> futures =
          instrumenItemIds.map((id) => InstrumenItemRepo.getById(id)).toList();

      final instrumenItems = await Future.wait(futures);

      final List<Map<String, dynamic>> result = [];
      for (int i = 0; i < itemAsesmenList.length; i++) {
        result.add({
          'item_asesmen': itemAsesmenList[i],
          'instrumen_item': instrumenItems[i],
        });
      }

      return result;
    } catch (e) {
      debugPrint("Error getDetailAsesmen: $e");
      throw Exception("Gagal memuat detail asesmen: $e");
    }
  }

  void clearForm() {
    selectedInstrumenId = null;

    for (var controller in skorControllers.values) {
      controller.dispose();
    }
    skorControllers.clear();

    skorTotalController.clear();
    hasilInterpretasiController.clear();

    instrumenItems.clear();
    errorMessage = null;

    notifyListeners();
  }

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    for (var controller in skorControllers.values) {
      controller.dispose();
    }
    skorTotalController.dispose();
    hasilInterpretasiController.dispose();
    super.dispose();
  }
}
