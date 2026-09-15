import 'package:flutter/material.dart';
import 'package:emr_homemade/data/models/pasien_model.dart';
import 'package:emr_homemade/data/repositories/pasien_repo.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class PasienProvider with ChangeNotifier {
  PasienProvider(this.context) {
    loadPreferences();
    loadPasiens();
  }

  BuildContext context;

  List<PasienModel> pasiens = [];
  List<PasienModel> filteredPasiens = [];

  bool isLoading = false;
  bool isSearching = false;
  String? errorMessage;

  int? sortColumnIndex;
  bool sortAscending = true;

  DateFormat dateFormat = DateFormat('yyyy-MM-dd');

  TextEditingController nameTf = TextEditingController();
  TextEditingController addressTf = TextEditingController();
  TextEditingController phoneTf = TextEditingController();
  String? gender;
  DateTime? birthdate;
  TextEditingController allergyTf = TextEditingController();

  String? existingPasienId;
  bool filterOn = false;

  String? createdBy;
  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    createdBy = prefs.getString('username') ?? 'system';
    notifyListeners();
  }

  Future<void> loadPasiens() async {
    _setLoading(true);
    try {
      pasiens = await PasienRepo.getAll();
      filteredPasiens = pasiens;
      errorMessage = null;
    } catch (e) {
      errorMessage = "Gagal memuat data pasien: $e";
    }
    _setLoading(false);
  }

  Future<void> searchByName(String name) async {
    _setSearching(true);
    try {
      filteredPasiens = await PasienRepo.searchByName(name);
      errorMessage = null;
    } catch (e) {
      errorMessage = "Gagal mencari pasien: $e";
    }
    _setSearching(false);
  }

  Future<bool> addPasien() async {
  try {
    final pasien = PasienModel(
      patientName: nameTf.text,
      patientAddress: addressTf.text,
      patientGender: gender ?? "L",
      patientBirthdate: birthdate ?? DateTime.now(),
      patientPhone: phoneTf.text,
      patientAllergy: allergyTf.text,
      isActive: true,
      createdBy: createdBy ?? "system",
    );

    await PasienRepo.insert(pasien);
    await refreshData(); 
    clearForm();
    return true;
  } catch (e) {
    errorMessage = "Gagal menambahkan pasien: $e";
    notifyListeners();
    return false;
  }
}
  Future<bool> updatePasien(String modifiedBy) async {
    try {
      if (existingPasienId == null) return false;
      final pasien = PasienModel(
        pasienId: existingPasienId,
        patientName: nameTf.text,
        patientAddress: addressTf.text,
        patientGender: gender ?? "L",
        patientBirthdate: birthdate ?? DateTime.now(),
        patientPhone: phoneTf.text,
        patientAllergy: allergyTf.text,
        isActive: true,
        createdBy: createdBy ?? "system",
        modifiedBy: modifiedBy,
        modifyDate: DateTime.now(),
      );

      await PasienRepo.update(pasien);
      // HANYA update data, tidak melakukan navigasi
      await loadPasiens();
      clearForm();
      return true;
    } catch (e) {
      errorMessage = "Gagal update pasien: $e";
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletePasien(String id, String modifiedBy) async {
    try {
      await PasienRepo.delete(id, modifiedBy);
      await loadPasiens();
      return true;
    } catch (e) {
      errorMessage = "Gagal menghapus pasien: $e";
      notifyListeners();
      return false;
    }
  }

  Future<void> refreshData() async {
  await loadPasiens();
}

  void onTableSort(int columnIndex, bool ascending,
      Comparable Function(PasienModel d) getField) {
    sortColumnIndex = columnIndex;
    sortAscending = ascending;
    pasiens.sort((a, b) {
      final aValue = getField(a);
      final bValue = getField(b);
      return ascending
          ? Comparable.compare(aValue, bValue)
          : Comparable.compare(bValue, aValue);
    });
    notifyListeners();
  }

  void resetSort() {
    sortColumnIndex = null;
    sortAscending = true;
    filteredPasiens = pasiens;
    notifyListeners();
  }

  void clearForm() {
    nameTf.clear();
    addressTf.clear();
    phoneTf.clear();
    gender = null;
    birthdate = null;
    existingPasienId = null;
    allergyTf.clear();
    notifyListeners();
  }

  void setEditForm(PasienModel pasien) {
    existingPasienId = pasien.pasienId;
    nameTf.text = pasien.patientName;
    addressTf.text = pasien.patientAddress;
    phoneTf.text = pasien.patientPhone;
    allergyTf.text = pasien.patientAllergy;
    gender = pasien.patientGender;
    birthdate = pasien.patientBirthdate;
    notifyListeners();
  }

  /// Memberi tahu widget bahwa field yang di-set langsung dari UI
  /// (gender, birthdate) sudah berubah.
  ///
  /// Sebelumnya widget memanggil `prov.notifyListeners()` sendiri, padahal
  /// method itu `@protected` — hanya boleh dipanggil dari dalam provider.
  void refreshUi() => notifyListeners();

  void _setLoading(bool v) {
    isLoading = v;
    notifyListeners();
  }

  void _setSearching(bool v) {
    isSearching = v;
    notifyListeners();
  }
}
