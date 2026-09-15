import 'package:flutter/material.dart';
import 'package:emr_homemade/data/models/user_model.dart';
import 'package:emr_homemade/data/repositories/user_repo.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider with ChangeNotifier {
  UserProvider(this.context) {
    loadPreferences();
    refreshData();
  }

  final BuildContext context;

  List<UserModel> userList = [];
  List<UserModel> filteredUserList = [];
  bool isLoading = false;
  bool isSearching = false;
  bool filterOn = false;
  String? errorMessage;

  int? sortColumnIndex;
  bool sortAscending = true;

  TextEditingController userId = TextEditingController();
  TextEditingController username = TextEditingController();
  TextEditingController password = TextEditingController();
  TextEditingController name = TextEditingController();
  TextEditingController role = TextEditingController();
  TextEditingController usernameSearch = TextEditingController();

  TextEditingController userIdEdit = TextEditingController();
  TextEditingController usernameEdit = TextEditingController();
  TextEditingController passwordEdit = TextEditingController();
  TextEditingController nameEdit = TextEditingController();
  TextEditingController roleEdit = TextEditingController();

  String? existingUserId;
  String? createdBy;
  bool isActive = true;
  bool isActiveEdit = true;

  bool get formValid =>
      username.text.trim().isNotEmpty && 
      password.text.trim().isNotEmpty && 
      name.text.trim().isNotEmpty &&
      role.text.trim().isNotEmpty;

  bool get editFormValid => 
      usernameEdit.text.trim().isNotEmpty && 
      nameEdit.text.trim().isNotEmpty &&
      roleEdit.text.trim().isNotEmpty;

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    createdBy = prefs.getString('username') ?? 'system';
    notifyListeners();
  }

  Future<void> refreshData() async {
    _setLoading(true);
    try {
      userList = await UserRepo.getAll();
      filteredUserList = userList;
      errorMessage = null;
    } catch (e) {
      errorMessage = "Gagal memuat data user: $e";
    }
    _setLoading(false);
  }

  void performSearch(String query) {
    if (query.isEmpty) {
      filteredUserList = userList;
      filterOn = false;
    } else {
      final lowerQuery = query.toLowerCase();
      filteredUserList = userList.where((user) {
        return user.username.toLowerCase().contains(lowerQuery) ||
               user.name.toLowerCase().contains(lowerQuery) ||
               user.role.toLowerCase().contains(lowerQuery);
      }).toList();
      filterOn = true;
    }
    notifyListeners();
  }

  Future<void> searchUser(String query) async {
    _setSearching(true);
    try {
      if (query.isEmpty) {
        filteredUserList = userList;
      } else {
        filteredUserList = await UserRepo.searchByUsername(query);
      }
      errorMessage = null;
    } catch (e) {
      errorMessage = "Gagal mencari user: $e";
    }
    _setSearching(false);
  }

  Future<bool> createUser() async {
    try {
      final user = UserModel(
        username: username.text,
        password: password.text,
        name: name.text,
        role: role.text,
        isActive: isActive,
        createdBy: createdBy ?? "system",
      );

      await UserRepo.insert(user);
      await refreshData();
      return true;
    } catch (e) {
      errorMessage = "Gagal menambahkan user: $e";
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateUser() async {
    try {
      final user = UserModel(
        userId: existingUserId,
        username: usernameEdit.text,
        password: passwordEdit.text.isNotEmpty ? passwordEdit.text : userList.firstWhere((u) => u.userId == existingUserId).password,
        name: nameEdit.text,
        role: roleEdit.text,
        isActive: isActiveEdit,
        createdBy: userList.firstWhere((u) => u.userId == existingUserId).createdBy,
      );

      await UserRepo.update(user);
      await refreshData();
      clearEditForm();
      return true;
    } catch (e) {
      errorMessage = "Gagal mengupdate user: $e";
      notifyListeners();
      return false;
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await UserRepo.delete(userId, createdBy ?? "system");
      await refreshData();
    } catch (e) {
      errorMessage = "Gagal menghapus user: $e";
      notifyListeners();
    }
  }

  void setEditForm(UserModel user) {
    existingUserId = user.userId;
    userIdEdit.text = user.userId;
    usernameEdit.text = user.username;
    nameEdit.text = user.name;
    roleEdit.text = user.role;
    isActiveEdit = user.isActive;
    notifyListeners();
  }

  void clearForm() {
    userId.clear();
    username.clear();
    password.clear();
    name.clear();
    role.clear();
    isActive = true;
    notifyListeners();
  }

  void clearEditForm() {
    userIdEdit.clear();
    usernameEdit.clear();
    passwordEdit.clear();
    nameEdit.clear();
    roleEdit.clear();
    existingUserId = null;
    isActiveEdit = true;
    notifyListeners();
  }

  void changeFilter(bool isFiltered) {
    filterOn = isFiltered;
    notifyListeners();
  }

  void onTableSort(int columnIndex, bool ascending, Comparable Function(UserModel d) getField) {
    sortColumnIndex = columnIndex;
    sortAscending = ascending;

    filteredUserList.sort((a, b) {
      final aValue = getField(a);
      final bValue = getField(b);
      return ascending
          ? Comparable.compare(aValue, bValue)
          : Comparable.compare(bValue, aValue);
    });
    notifyListeners();
  }

  /// Memberi tahu widget bahwa field yang di-set langsung dari UI
  /// (isActive, isActiveEdit) sudah berubah.
  ///
  /// Sebelumnya widget memanggil `prov.notifyListeners()` sendiri, padahal
  /// method itu `@protected` — hanya boleh dipanggil dari dalam provider.
  void refreshUi() => notifyListeners();

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  void _setSearching(bool value) {
    isSearching = value;
    notifyListeners();
  }

}