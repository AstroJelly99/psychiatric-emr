import 'package:flutter/material.dart';
import 'package:emr_homemade/data/models/instrumen_item_model.dart';
import 'package:emr_homemade/data/models/pasien_model.dart';
import 'package:emr_homemade/data/repositories/instrumen_item_repo.dart';
import 'package:emr_homemade/data/repositories/item_asesmen_psikologis_repo.dart';
import 'package:emr_homemade/data/repositories/pasien_repo.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:emr_homemade/data/models/asesmen_psikologis_model.dart';
import 'package:emr_homemade/data/models/instrumen_model.dart';
import 'package:emr_homemade/data/repositories/asesmen_psikologis_repo.dart';
import 'package:emr_homemade/data/repositories/instrumen_repo.dart';

class ManageAsesmenPsikologisProvider with ChangeNotifier {
  ManageAsesmenPsikologisProvider(this.context) {
    loadPreferences();
    loadInitialData();
  }

  final BuildContext context;

  bool isLoading = false;
  String? errorMessage;

  List<PasienModel> pasienList = [];
  List<InstrumenModel> instrumenList = [];
  List<AsesmenPsikologisModel> asesmenList = [];
  List<AsesmenPsikologisModel> filteredAsesmenList = [];

  String? selectedPasienFilter;
  String? selectedInstrumenFilter;
  DateTime? startDateFilter;
  DateTime? endDateFilter;

  List<double> chartData = [];
  List<String> chartLabels = [];

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
      final results = await Future.wait([
        PasienRepo.getAll(),
        InstrumenRepo.getAll(),
        AsesmenPsikologisRepo.getAll(),
      ]);

      pasienList = results[0] as List<PasienModel>;
      instrumenList = results[1] as List<InstrumenModel>;
      asesmenList = results[2] as List<AsesmenPsikologisModel>;

      _applyLocalFilters();
      errorMessage = null;
    } catch (e) {
      errorMessage = "Gagal memuat data: $e";
      debugPrint("Error loadInitialData: $e");
    }
    _setLoading(false);
  }

  Future<void> applyFilters() async {
    _setLoading(true);
    try {
      _applyLocalFilters();
      errorMessage = null;
    } catch (e) {
      errorMessage = "Gagal menerapkan filter: $e";
      debugPrint("Error applyFilters: $e");
    }
    _setLoading(false);
  }

  void _applyLocalFilters() {
    List<AsesmenPsikologisModel> filtered = List.from(asesmenList);

    if (selectedPasienFilter != null) {
      filtered = filtered
          .where((asesmen) => asesmen.pasienId == selectedPasienFilter)
          .toList();
    }

    if (selectedInstrumenFilter != null) {
      filtered = filtered
          .where((asesmen) => asesmen.instrumenId == selectedInstrumenFilter)
          .toList();
    }

    if (startDateFilter != null) {
      filtered = filtered
          .where((asesmen) =>
              asesmen.tanggalAsesmen != null &&
              asesmen.tanggalAsesmen!
                  .isAfter(startDateFilter!.subtract(const Duration(days: 1))))
          .toList();
    }

    if (endDateFilter != null) {
      filtered = filtered
          .where((asesmen) =>
              asesmen.tanggalAsesmen
                  ?.isBefore(endDateFilter!.add(const Duration(days: 1))) ??
              false)
          .toList();
    }

    filteredAsesmenList = filtered;
    _prepareChartData();
    notifyListeners();
  }

  void _prepareChartData() {
    if (filteredAsesmenList.isEmpty) {
      chartData = [];
      chartLabels = [];
      return;
    }

    filteredAsesmenList.sort((a, b) {
      if (a.tanggalAsesmen == null || b.tanggalAsesmen == null) {
        return 0;
      }
      return a.tanggalAsesmen!.compareTo(b.tanggalAsesmen!);
    });

    chartData = filteredAsesmenList
        .map((asesmen) => asesmen.skorTotal.toDouble())
        .toList();
    chartLabels = filteredAsesmenList.map((asesmen) {
      final date = asesmen.tanggalAsesmen;
      return "${date?.day}/${date?.month}";
    }).toList();

    notifyListeners();
  }

  Future<bool> deleteAsesmen(String asesmenId) async {
    try {
      await AsesmenPsikologisRepo.delete(asesmenId, createdBy!);

      asesmenList.removeWhere((asesmen) => asesmen.asesmenId == asesmenId);
      _applyLocalFilters();
      return true;
    } catch (e) {
      errorMessage = "Gagal menghapus asesmen: $e";
      notifyListeners();
      return false;
    }
  }

  void resetFilters() {
    selectedPasienFilter = null;
    selectedInstrumenFilter = null;
    startDateFilter = null;
    endDateFilter = null;
    _applyLocalFilters();
  }

  bool hasActiveFilters() {
    return selectedPasienFilter != null ||
        selectedInstrumenFilter != null ||
        startDateFilter != null ||
        endDateFilter != null;
  }

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  String getPasienName(String pasienId) {
    try {
      return pasienList.firstWhere((p) => p.pasienId == pasienId).patientName;
    } catch (e) {
      return 'Unknown';
    }
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

  String getAverageScore() {
    if (filteredAsesmenList.isEmpty) return "0";

    final total = filteredAsesmenList.fold<int>(
      0,
      (sum, asesmen) => sum + asesmen.skorTotal,
    );

    final average = total / filteredAsesmenList.length;
    return average.toStringAsFixed(1);
  }

  List<Map<String, dynamic>> getScoreDistribution() {
    if (filteredAsesmenList.isEmpty) return [];

    final Map<String, int> distribution = {};

    for (var asesmen in filteredAsesmenList) {
      final interpretation = asesmen.hasilInterpretasi;
      distribution[interpretation] = (distribution[interpretation] ?? 0) + 1;
    }

    final List<Map<String, dynamic>> result = [];

    distribution.forEach((category, count) {
      Color color;
      switch (category.toLowerCase()) {
        // HAM-A colors
        case 'mild anxiety':
          color = Colors.blue;
          break;
        case 'moderate anxiety':
          color = Colors.orange;
          break;
        case 'severe anxiety':
          color = Colors.red;
          break;
        case 'very severe anxiety':
          color = Colors.purple;
          break;

        // HAM-D colors
        case 'normal':
          color = Colors.green;
          break;
        case 'mild depression':
          color = Colors.blue;
          break;
        case 'moderate depression':
          color = Colors.orange;
          break;
        case 'severe depression':
          color = Colors.red;
          break;
        case 'very severe depression':
          color = Colors.purple;
          break;

        // Default colors (untuk instrumen lain)
        case 'tinggi':
          color = Colors.red;
          break;
        case 'sedang':
          color = Colors.orange;
          break;
        case 'rendah':
          color = Colors.green;
          break;
        default:
          color = Colors.grey;
      }

      result.add({
        'category': category,
        'count': count,
        'color': color,
      });
    });

    return result;
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
}
