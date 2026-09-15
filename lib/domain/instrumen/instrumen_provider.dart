import 'package:flutter/material.dart';
import 'package:emr_homemade/data/models/instrumen_model.dart';
import 'package:emr_homemade/data/repositories/instrumen_item_repo.dart';
import 'package:emr_homemade/data/repositories/instrumen_repo.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InstrumenProvider with ChangeNotifier {
  InstrumenProvider(this.context) {
    loadPreferences();
    getInstrumens();
  }

  final BuildContext context;

  List<InstrumenModel> instrumens = [];
  List<InstrumenModel> filteredInstrumens = [];
  bool isLoading = false;
  bool isSearching = false;
  String? errorMessage;

  int? sortColumnIndex;
  bool sortAscending = true;

  TextEditingController versi = TextEditingController();
  TextEditingController namaInstrumen = TextEditingController();
  TextEditingController deskripsi = TextEditingController();
  TextEditingController namaInstrumenSearch = TextEditingController();
  TextEditingController versiEdit = TextEditingController();
  TextEditingController namaInstrumenEdit = TextEditingController();
  TextEditingController deskripsiEdit = TextEditingController();

  String? existingInstrumenId;
  bool filterOn = false;
  String? createdBy;

  Future<void> refreshData() async {
    await getInstrumens();
  }

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    createdBy = prefs.getString('username') ?? 'system';
    notifyListeners();
  }

  Future<void> getInstrumens() async {
    _setLoading(true);
    try {
      instrumens = await InstrumenRepo.getAll();
      filteredInstrumens = instrumens;
      errorMessage = null;
      notifyListeners();
    } catch (e) {
      errorMessage = "Gagal memuat data instrumen: $e";
    }
    _setLoading(false);
  }

  Future<void> getInstrumenFilter(String name) async {
    _setSearching(true);
    try {
      filteredInstrumens = await InstrumenRepo.searchByName(name);
      errorMessage = null;
    } catch (e) {
      errorMessage = "Gagal mencari instrumen: $e";
    }
    _setSearching(false);
  }

  Future<bool> addInstrumen() async {
    try {
      final instrumen = InstrumenModel(
        versi: versi.text,
        namaInstrumen: namaInstrumen.text,
        deskripsi: deskripsi.text,
        isActive: true,
        createdBy: createdBy ?? "system",
      );

      await InstrumenRepo.insert(instrumen);
      await refreshData();
      return true;
    } catch (e) {
      errorMessage = "Gagal menambahkan instrumen: $e";
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteInstrumen(String instrumenId, String modifiedBy) async {
    final hasItems = await InstrumenItemRepo.hasItems(instrumenId);
    if (hasItems) {
      errorMessage =
          "Tidak dapat menghapus instrumen karena terdapat item di dalamnya";
      notifyListeners();
      return false;
    }

    try {
      await InstrumenRepo.delete(instrumenId, createdBy ?? "system");
      await getInstrumens();
      return true;
    } catch (e) {
      errorMessage = "Gagal menghapus instrumen: $e";
      notifyListeners();
      return false;
    }
  }

  Future<bool> activateInstrumen(String instrumenId, String s) async {
    try {
      await InstrumenRepo.activate(instrumenId, createdBy ?? "system");
      await getInstrumens();
      return true;
    } catch (e) {
      errorMessage = "Gagal mengaktifkan instrumen: $e";
      notifyListeners();
      return false;
    }
  }

  void changeFilter(bool isFiltered) {
    filterOn = isFiltered;
    notifyListeners();
  }

  void onTableSort(int columnIndex, bool ascending,
      Comparable Function(InstrumenModel d) getField) {
    sortColumnIndex = columnIndex;
    sortAscending = ascending;

    filteredInstrumens.sort((a, b) {
      final aValue = getField(a);
      final bValue = getField(b);
      return ascending
          ? Comparable.compare(aValue, bValue)
          : Comparable.compare(bValue, aValue);
    });
    notifyListeners();
  }

  void clearForm() {
    versi.clear();
    namaInstrumen.clear();
    deskripsi.clear();
    existingInstrumenId = null;
    notifyListeners();
  }

  void setEditForm(InstrumenModel instrumen) {
    existingInstrumenId = instrumen.instrumenId;
    versiEdit.text = instrumen.versi;
    namaInstrumenEdit.text = instrumen.namaInstrumen;
    deskripsiEdit.text = instrumen.deskripsi;
    notifyListeners();
  }

  bool get formValid =>
      versi.text.trim().isNotEmpty && namaInstrumen.text.trim().isNotEmpty;

  bool get editFormValid =>
      versiEdit.text.trim().isNotEmpty &&
      namaInstrumenEdit.text.trim().isNotEmpty;

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  void _setSearching(bool value) {
    isSearching = value;
    notifyListeners();
  }

  Future<bool> updateInstrumen() async {
    try {
      final instrumen = InstrumenModel(
        instrumenId: existingInstrumenId,
        versi: versiEdit.text,
        namaInstrumen: namaInstrumenEdit.text,
        deskripsi: deskripsiEdit.text,
        isActive: true,
        createdBy: createdBy ?? "system",
      );

      await InstrumenRepo.update(instrumen);
      await getInstrumens();
      clearEditForm();
      return true;
    } catch (e) {
      errorMessage = "Gagal mengupdate instrumen: $e";
      notifyListeners();
      return false;
    }
  }

  void clearEditForm() {
    versiEdit.clear();
    namaInstrumenEdit.clear();
    deskripsiEdit.clear();
    existingInstrumenId = null;
    notifyListeners();
  }
}
