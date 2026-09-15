import 'package:flutter/material.dart';
import 'package:emr_homemade/data/models/obat_model.dart';
import 'package:emr_homemade/data/repositories/obat_repo.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ObatProvider with ChangeNotifier {
  ObatProvider(this.context) {
    loadPreferences();
    refreshData();
  }

  final BuildContext context;

  List<ObatModel> obatList = [];
  List<ObatModel> filteredObatList = [];
  bool isLoading = false;
  bool isSearching = false;
  bool filterOn = false;
  String? errorMessage;

  int? sortColumnIndex;
  bool sortAscending = true;

  TextEditingController namaObat = TextEditingController();
  TextEditingController namaGenerik = TextEditingController();
  TextEditingController kategori = TextEditingController();
  TextEditingController deskripsi = TextEditingController();
  TextEditingController namaObatSearch = TextEditingController();

  TextEditingController namaObatEdit = TextEditingController();
  TextEditingController namaGenerikEdit = TextEditingController();
  TextEditingController kategoriEdit = TextEditingController();
  TextEditingController deskripsiEdit = TextEditingController();

  String? existingObatId;
  String? createdBy;

  bool get formValid => namaObat.text.trim().isNotEmpty && kategori.text.trim().isNotEmpty;
  bool get editFormValid => namaObatEdit.text.trim().isNotEmpty && kategoriEdit.text.trim().isNotEmpty;

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    createdBy = prefs.getString('username') ?? 'system';
    notifyListeners();
  }

  Future<void> refreshData() async {
    _setLoading(true);
    try {
      obatList = await ObatRepo.getAll();
      filteredObatList = obatList;
      errorMessage = null;
    } catch (e) {
      errorMessage = "Gagal memuat data obat: $e";
    }
    _setLoading(false);
  }

  void performSearch(String query) {
    if (query.isEmpty) {
      filteredObatList = obatList;
      filterOn = false;
    } else {
      final lowerQuery = query.toLowerCase();
      filteredObatList = obatList.where((obat) {
        return obat.namaObat.toLowerCase().contains(lowerQuery) ||
               obat.kategori.toLowerCase().contains(lowerQuery) ||
               (obat.namaGenerik?.toLowerCase().contains(lowerQuery) ?? false) ||
               (obat.deskripsi?.toLowerCase().contains(lowerQuery) ?? false);
      }).toList();
      filterOn = true;
    }
    notifyListeners();
  }

  Future<void> searchObat(String query) async {
    _setSearching(true);
    try {
      if (query.isEmpty) {
        filteredObatList = obatList;
      } else {
        filteredObatList = await ObatRepo.searchByName(query);
      }
      errorMessage = null;
    } catch (e) {
      errorMessage = "Gagal mencari obat: $e";
    }
    _setSearching(false);
  }

  Future<bool> createObat() async {
    try {
      final obat = ObatModel(
        namaObat: namaObat.text,
        namaGenerik: namaGenerik.text.isEmpty ? null : namaGenerik.text,
        kategori: kategori.text,
        deskripsi: deskripsi.text.isEmpty ? null : deskripsi.text,
        isActive: true,
        createdBy: createdBy ?? "system",
      );

      await ObatRepo.insert(obat);
      await refreshData();
      return true;
    } catch (e) {
      errorMessage = "Gagal menambahkan obat: $e";
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateObat() async {
    try {
      final obat = ObatModel(
        obatId: existingObatId,
        namaObat: namaObatEdit.text,
        namaGenerik: namaGenerikEdit.text.isEmpty ? null : namaGenerikEdit.text,
        kategori: kategoriEdit.text,
        deskripsi: deskripsiEdit.text.isEmpty ? null : deskripsiEdit.text,
        isActive: true,
        createdBy: createdBy ?? "system",
      );

      await ObatRepo.update(obat);
      await refreshData();
      clearEditForm();
      return true;
    } catch (e) {
      errorMessage = "Gagal mengupdate obat: $e";
      notifyListeners();
      return false;
    }
  }

  Future<void> deleteObat(String obatId) async {
    try {
      await ObatRepo.delete(obatId, createdBy ?? "system");
      await refreshData();
    } catch (e) {
      errorMessage = "Gagal menghapus obat: $e";
      notifyListeners();
    }
  }

  void setEditForm(ObatModel obat) {
    existingObatId = obat.obatId;
    namaObatEdit.text = obat.namaObat;
    namaGenerikEdit.text = obat.namaGenerik ?? '';
    kategoriEdit.text = obat.kategori;
    deskripsiEdit.text = obat.deskripsi ?? '';
    notifyListeners();
  }

  void clearForm() {
    namaObat.clear();
    namaGenerik.clear();
    kategori.clear();
    deskripsi.clear();
    notifyListeners();
  }

  void clearEditForm() {
    namaObatEdit.clear();
    namaGenerikEdit.clear();
    kategoriEdit.clear();
    deskripsiEdit.clear();
    existingObatId = null;
    notifyListeners();
  }

  void changeFilter(bool isFiltered) {
    filterOn = isFiltered;
    notifyListeners();
  }

  void onTableSort(int columnIndex, bool ascending, Comparable Function(ObatModel d) getField) {
    sortColumnIndex = columnIndex;
    sortAscending = ascending;

    filteredObatList.sort((a, b) {
      final aValue = getField(a);
      final bValue = getField(b);
      return ascending
          ? Comparable.compare(aValue, bValue)
          : Comparable.compare(bValue, aValue);
    });
    notifyListeners();
  }

  Future<int> getInteractionCount(String obatId) async {
    try {
      return await ObatRepo.getInteractionCount(obatId);
    } catch (e) {
      debugPrint('Error getting interaction count: $e');
      return 0;
    }
  }

  Future<List<DrugInteractionModel>> getInteractions(String obatId) async {
    try {
      return await ObatRepo.getInteractionsByObatId(obatId);
    } catch (e) {
      _showError('Gagal memuat interaksi: $e');
      return [];
    }
  }

  Future<void> addInteraction(DrugInteractionModel interaction) async {
    try {
      await ObatRepo.insertInteraction(interaction);
      _showSuccess('Interaksi berhasil ditambahkan');
      notifyListeners();
    } catch (e) {
      _showError('Gagal menambahkan interaksi: $e');
    }
  }

  Future<void> updateInteraction(DrugInteractionModel interaction) async {
    try {
      interaction.modifiedBy = 'USER';
      await ObatRepo.updateInteraction(interaction);
      _showSuccess('Interaksi berhasil diupdate');
      notifyListeners();
    } catch (e) {
      _showError('Gagal mengupdate interaksi: $e');
    }
  }

  Future<void> deleteInteraction(String interactionId) async {
    try {
      await ObatRepo.deleteInteraction(interactionId, 'USER');
      _showSuccess('Interaksi berhasil dihapus');
      notifyListeners();
    } catch (e) {
      _showError('Gagal menghapus interaksi: $e');
    }
  }

  Future<List<DrugInteractionModel>> checkMultipleInteractions(List<String> obatIds) async {
    try {
      return await ObatRepo.checkMultipleInteractions(obatIds);
    } catch (e) {
      _showError('Gagal memeriksa interaksi: $e');
      return [];
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Color getSeverityColor(SeverityLevel severity) {
    switch (severity) {
      case SeverityLevel.MINOR:
        return Colors.yellow[700]!;
      case SeverityLevel.MODERATE:
        return Colors.orange[700]!;
      case SeverityLevel.MAJOR:
        return Colors.red[700]!;
      case SeverityLevel.CONTRAINDICATED:
        // Lebih gelap dari MAJOR: kombinasi yang tidak boleh diresepkan sama
        // sekali, bukan sekadar perlu diwaspadai.
        return Colors.red[900]!;
    }
  }

  String getSeverityLabel(SeverityLevel severity) {
    switch (severity) {
      case SeverityLevel.MINOR:
        return 'Minor';
      case SeverityLevel.MODERATE:
        return 'Moderate';
      case SeverityLevel.MAJOR:
        return 'Major';
      case SeverityLevel.CONTRAINDICATED:
        return 'Kontraindikasi';
    }
  }

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  void _setSearching(bool value) {
    isSearching = value;
    notifyListeners();
  }
}