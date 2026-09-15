import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:emr_homemade/data/models/instrumen_item_model.dart';
import 'package:emr_homemade/data/repositories/instrumen_item_repo.dart';
import 'package:emr_homemade/data/models/instrumen_model.dart';
import 'package:emr_homemade/data/repositories/instrumen_repo.dart';

class InstrumenItemProvider with ChangeNotifier {
  InstrumenItemProvider(this.context) {
    loadPreferences();
    getInstrumenItems();
    loadInstrumens();
  }

  final BuildContext context;

  List<InstrumenItemModel> instrumenItems = [];
  List<InstrumenItemModel> filteredInstrumenItems = [];
  List<InstrumenModel> instrumens = [];
  bool isLoading = false;
  bool isSearching = false;
  String? errorMessage;

  int? sortColumnIndex;
  bool sortAscending = true;

  TextEditingController pertanyaan = TextEditingController();
  TextEditingController teksPertanyaan = TextEditingController();
  TextEditingController nomerItem = TextEditingController();
  TextEditingController kategoriSkoring = TextEditingController();
  TextEditingController searchController = TextEditingController();
  TextEditingController editPertanyaan = TextEditingController();
  TextEditingController editTeksPertanyaan = TextEditingController();
  TextEditingController editNomerItem = TextEditingController();
  TextEditingController editKategoriSkoring = TextEditingController();

  String? selectedInstrumenFilter;
  String? searchFilter;

  String? existingInstrumenItemId;
  bool filterOn = false;
  String? createdBy;
  String? selectedInstrumenEdit;
  Future<void> refreshData() async {
  await getInstrumenItems();
  await loadInstrumens();
}

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    createdBy = prefs.getString('username') ?? 'system';
    notifyListeners();
  }

  

  Future<void> loadInstrumens() async {
    try {
      instrumens = await InstrumenRepo.getAll();
      notifyListeners();
    } catch (e) {
      errorMessage = "Gagal memuat data instrumen: $e";
      notifyListeners();
    }
  }


  Future<void> getInstrumenItems() async {
    _setLoading(true);
    try {
      instrumenItems = await InstrumenItemRepo.getAll();
      filteredInstrumenItems = instrumenItems;
      errorMessage = null;
    } catch (e) {
      errorMessage = "Gagal memuat data instrumen item: $e";
    }
    _setLoading(false);
  }

  Future<void> applyFilters() async {
    _setSearching(true);
    try {
      List<InstrumenItemModel> results = instrumenItems;

      if (selectedInstrumenFilter != null) {
        results = results.where((item) => item.instrumenId == selectedInstrumenFilter).toList();
      }

      if (searchFilter != null && searchFilter!.isNotEmpty) {
        results = results.where((item) =>
            item.pertanyaan.toLowerCase().contains(searchFilter!.toLowerCase()) ||
            item.teksPertanyaan.toLowerCase().contains(searchFilter!.toLowerCase())).toList();
      }

      filteredInstrumenItems = results;
      errorMessage = null;
    } catch (e) {
      errorMessage = "Gagal menerapkan filter: $e";
    }
    _setSearching(false);
  }

  void resetFilters() {
    selectedInstrumenFilter = null;
    searchController.clear();
    searchFilter = null;
    filteredInstrumenItems = instrumenItems;
    notifyListeners();
  }

Future<bool> addInstrumenItem() async {
  try {
    final instrumenItem = InstrumenItemModel(
      instrumenId: selectedInstrumenFilter!,
      pertanyaan: pertanyaan.text,
      teksPertanyaan: teksPertanyaan.text,
      nomerItem: int.parse(nomerItem.text),
      kategoriSkoring: kategoriSkoring.text,
      isActive: true,
      createdBy: createdBy ?? "system",
    );

    await InstrumenItemRepo.insert(instrumenItem);
    await refreshData(); 
    return true;
  } catch (e) {
    errorMessage = "Gagal menambahkan instrumen item: $e";
    notifyListeners();
    return false;
  }
}



  Future<bool> deleteInstrumenItem(String instrumenItemId) async {
    try {
      await InstrumenItemRepo.delete(instrumenItemId, createdBy ?? "system");
      await getInstrumenItems();
      await loadInstrumens();
      return true;
    } catch (e) {
      errorMessage = "Gagal menghapus instrumen item: $e";
      notifyListeners();
      return false;
    }
  }

  void setEditForm(InstrumenItemModel instrumenItem) {
    existingInstrumenItemId = instrumenItem.instrumenItemId;
    selectedInstrumenEdit = instrumenItem.instrumenId;
    editPertanyaan.text = instrumenItem.pertanyaan;
    editTeksPertanyaan.text = instrumenItem.teksPertanyaan;
    editNomerItem.text = instrumenItem.nomerItem.toString();
    editKategoriSkoring.text = instrumenItem.kategoriSkoring;
    notifyListeners();
  }

  Future<bool> updateInstrumenItem() async {
    try {
      final instrumenItem = InstrumenItemModel(
        instrumenItemId: existingInstrumenItemId,
        instrumenId: selectedInstrumenEdit!,
        pertanyaan: editPertanyaan.text,
        teksPertanyaan: editTeksPertanyaan.text,
        nomerItem: int.parse(editNomerItem.text),
        kategoriSkoring: editKategoriSkoring.text,
        isActive: true,
        createdBy: createdBy ?? "system",
      );

      await InstrumenItemRepo.update(instrumenItem);
      await getInstrumenItems();
      clearEditForm();
      return true;
    } catch (e) {
      errorMessage = "Gagal mengupdate instrumen item: $e";
      notifyListeners();
      return false;
    }
  }
  void clearForm() {
    pertanyaan.clear();
    teksPertanyaan.clear();
    nomerItem.clear();
    kategoriSkoring.clear();
    selectedInstrumenFilter = null;
    existingInstrumenItemId = null;
    notifyListeners();
  }

  void clearEditForm() {
    editPertanyaan.clear();
    editTeksPertanyaan.clear();
    editNomerItem.clear();
    editKategoriSkoring.clear();
    selectedInstrumenEdit = null;
    existingInstrumenItemId = null;
    notifyListeners();
  }

  bool get editFormValid =>
      selectedInstrumenEdit != null &&
      editPertanyaan.text.trim().isNotEmpty &&
      editTeksPertanyaan.text.trim().isNotEmpty &&
      editNomerItem.text.trim().isNotEmpty &&
      editKategoriSkoring.text.trim().isNotEmpty;

  bool get formValid =>
      selectedInstrumenFilter != null &&
      pertanyaan.text.trim().isNotEmpty &&
      teksPertanyaan.text.trim().isNotEmpty &&
      nomerItem.text.trim().isNotEmpty &&
      kategoriSkoring.text.trim().isNotEmpty;

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  void _setSearching(bool value) {
    isSearching = value;
    notifyListeners();
  }

  void onTableSort(int columnIndex, bool ascending,
      Comparable Function(InstrumenItemModel d) getField) {
    sortColumnIndex = columnIndex;
    sortAscending = ascending;

    filteredInstrumenItems.sort((a, b) {
      final aValue = getField(a);
      final bValue = getField(b);
      return ascending
          ? Comparable.compare(aValue, bValue)
          : Comparable.compare(bValue, aValue);
    });
    notifyListeners();
  }
}