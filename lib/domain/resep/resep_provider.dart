import 'package:flutter/material.dart';
import 'package:emr_homemade/data/models/resep_model.dart';
import 'package:emr_homemade/data/repositories/resep_repo.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ResepProvider with ChangeNotifier {
  ResepProvider(this.context) {
    loadPreferences();
  }

  final BuildContext context;
  
  List<ResepModel> _resepList = [];
  List<ResepModel> get resepList => _resepList;
  
  ResepModel? _selectedResep;
  ResepModel? get selectedResep => _selectedResep;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  
  String? createdBy;
  
  TextEditingController catatanTf = TextEditingController();
  
  DateTime? _tanggalResep;
  DateTime? get tanggalResep => _tanggalResep;
  
  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    createdBy = prefs.getString('username') ?? 'system';
    notifyListeners();
  }

  Future<void> loadResepByKunjunganId(String kunjunganId) async {
    _setLoading(true);
    try {
      _resepList = await ResepRepository.getByKunjunganId(kunjunganId);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = "Gagal memuat data resep: $e";
    }
    _setLoading(false);
  }

  /// Resep dari SELURUH kunjungan pasien ini, terbaru lebih dulu.
  ///
  /// Disimpan terpisah dari [resepList] dengan sengaja: [resepList] adalah
  /// resep pada kunjungan yang sedang dibuka — itu yang disunting dan
  /// disimpan. Riwayat di bawah ini hanya untuk dilihat sebagai rujukan.
  /// Menggabungkan keduanya akan membuat resep kunjungan lain ikut terlihat
  /// seolah milik kunjungan ini.
  List<ResepModel> _riwayatResep = [];
  List<ResepModel> get riwayatResep => _riwayatResep;

  bool _riwayatLoading = false;
  bool get riwayatLoading => _riwayatLoading;

  /// Memuat SELURUH resep pasien tanpa menyaring apa pun.
  ///
  /// Penyaringan sengaja diserahkan ke widget, bukan dilakukan di sini.
  /// Sebabnya konkret: dua tempat memakai daftar yang sama dengan aturan
  /// berbeda — form resep ingin membuang resep kunjungan yang sedang dibuka,
  /// sedangkan kartu rujukan di form kunjungan justru ingin resep milik satu
  /// kunjungan lama tertentu. Kalau penyaringannya di provider, keduanya
  /// saling menimpa isi daftar dan yang terakhir memuat menang.
  Future<void> loadRiwayatResep(String pasienId) async {
    _riwayatLoading = true;
    notifyListeners();
    try {
      _riwayatResep = await ResepRepository.getByPasienId(pasienId);
    } catch (e) {
      _riwayatResep = [];
      _errorMessage = "Gagal memuat riwayat resep: $e";
    }
    _riwayatLoading = false;
    notifyListeners();
  }

  Future<bool> addResep(String pasienId, String kunjunganId) async {
    try {
      final resep = ResepModel(
        tanggalResep: _tanggalResep ?? DateTime.now(),
        catatan: catatanTf.text,
        pasienId: pasienId,
        kunjunganId: kunjunganId,
        isActive: true,
        createdBy: createdBy ?? "system",
      );

      await ResepRepository.insert(resep);
      await loadResepByKunjunganId(kunjunganId);
      await loadRiwayatResep(pasienId);
      clearForm();
      return true;
    } catch (e) {
      _errorMessage = "Gagal menambahkan resep: $e";
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateResep(String modifiedBy) async {
    try {
      if (_selectedResep == null) return false;
      
      final resep = ResepModel(
        resepId: _selectedResep!.resepId,
        tanggalResep: _tanggalResep ?? DateTime.now(),
        catatan: catatanTf.text,
        pasienId: _selectedResep!.pasienId,
        kunjunganId: _selectedResep!.kunjunganId,
        isActive: true,
        createDate: _selectedResep!.createDate,
        createdBy: _selectedResep!.createdBy,
        modifiedBy: modifiedBy,
      );

      await ResepRepository.update(resep);
      await loadResepByKunjunganId(_selectedResep!.kunjunganId);
      await loadRiwayatResep(_selectedResep!.pasienId);
      clearForm();
      return true;
    } catch (e) {
      _errorMessage = "Gagal mengupdate resep: $e";
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteResep(String resepId, String kunjunganId) async {
    try {
      // Diambil SEBELUM dihapus: setelah `loadResepByKunjunganId` di bawah,
      // resep ini sudah tidak ada di daftar mana pun dan pasienId-nya hilang.
      final pasienId = _cariPasienId(resepId);
      await ResepRepository.delete(resepId, createdBy ?? "system");
      await loadResepByKunjunganId(kunjunganId);
      if (pasienId != null) await loadRiwayatResep(pasienId);
      return true;
    } catch (e) {
      _errorMessage = "Gagal menghapus resep: $e";
      notifyListeners();
      return false;
    }
  }

  /// Mencari pasien pemilik sebuah resep dari daftar yang sudah ada di memori.
  ///
  /// `deleteResep` hanya menerima resepId dan kunjunganId, sedangkan riwayat
  /// disusun per pasien. Daripada mengubah tanda tangan method yang sudah
  /// dipakai di beberapa tempat, pasienId dicari saja dari daftar yang pasti
  /// memuat resep itu — kalau resepnya bisa ditampilkan untuk dihapus, ia ada
  /// di salah satu dari kedua daftar ini.
  String? _cariPasienId(String resepId) {
    for (final daftar in [_resepList, _riwayatResep]) {
      for (final r in daftar) {
        if (r.resepId == resepId) return r.pasienId;
      }
    }
    return null;
  }

  void setSelectedResep(ResepModel resep) {
    _selectedResep = resep;
    _tanggalResep = resep.tanggalResep;
    catatanTf.text = resep.catatan;
    notifyListeners();
  }

  void setTanggalResep(DateTime date) {
    _tanggalResep = date;
    notifyListeners();
  }

  void clearForm() {
    _selectedResep = null;
    _tanggalResep = DateTime.now();
    catatanTf.clear();
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}