import 'package:flutter/material.dart';
import 'package:emr_homemade/data/models/kunjungan_model.dart';
import 'package:emr_homemade/data/repositories/kunjungan_repo.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KunjunganProvider with ChangeNotifier {
  KunjunganProvider(this.context) {
    loadPreferences();
  }

  final BuildContext context;
  

  List<KunjunganModel> _kunjunganList = [];
  List<KunjunganModel> get kunjunganList => _kunjunganList;
  
  KunjunganModel? _selectedKunjungan;
  KunjunganModel? get selectedKunjungan => _selectedKunjungan;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  
  String? createdBy;
  

  TextEditingController keluhanUtamaTf = TextEditingController();
  TextEditingController riwayatSekarangTf = TextEditingController();
  TextEditingController riwayatDahuluTf = TextEditingController();
  TextEditingController riwayatKeluargaTf = TextEditingController();
  TextEditingController pemeriksaanFisikTf = TextEditingController();
  TextEditingController tekananDarahTf = TextEditingController();
  TextEditingController suhuTf = TextEditingController();
  TextEditingController skalaNyeriTf = TextEditingController();
  TextEditingController nadiTf = TextEditingController();
  TextEditingController respirationRateTf = TextEditingController();
  TextEditingController diagnosisTf = TextEditingController();
  TextEditingController terapiTf = TextEditingController();
  TextEditingController noteTf = TextEditingController();
  
  TextEditingController deskripsiUmumTf = TextEditingController();
  TextEditingController kontakTf = TextEditingController();
  TextEditingController kesadaranTf = TextEditingController();
  TextEditingController orientasiTf = TextEditingController();
  TextEditingController memoriTf = TextEditingController();
  TextEditingController konsentrasiTf = TextEditingController();
  TextEditingController moodTf = TextEditingController();
  TextEditingController prosesBerpikirTf = TextEditingController();
  TextEditingController persepsiTf = TextEditingController();
  TextEditingController kemauanTf = TextEditingController();
  TextEditingController psikomotorTf = TextEditingController();
  TextEditingController intelegensiTf = TextEditingController();
  
  DateTime? _tanggalKunjungan;
  DateTime? get tanggalKunjungan => _tanggalKunjungan;
  
  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    createdBy = prefs.getString('username') ?? 'system';
    notifyListeners();
  }

  Future<void> loadKunjunganByPasienId(String pasienId) async {
    _setLoading(true);
    try {
      _kunjunganList = await KunjunganRepo.getAllByPasienId(pasienId);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = "Gagal memuat data kunjungan: $e";
    }
    _setLoading(false);
  }

  Future<bool> addKunjungan(String pasienId) async {
    try {
      final kunjungan = KunjunganModel(
        tanggalKunjungan: _tanggalKunjungan ?? DateTime.now(),
        keluhanUtama: keluhanUtamaTf.text,
        riwayatPenyakitSekarang: riwayatSekarangTf.text,
        riwayatPenyakitDahulu: riwayatDahuluTf.text,
        riwayatPenyakitKeluarga: riwayatKeluargaTf.text,
        pemeriksaanFisik: pemeriksaanFisikTf.text,
        tekananDarah: tekananDarahTf.text,
        suhu: suhuTf.text,
        skalaNyeri: skalaNyeriTf.text,
        nadi: nadiTf.text.isNotEmpty ? nadiTf.text : null,
        respirationRate: respirationRateTf.text.isNotEmpty ? respirationRateTf.text : null,
        deskripsiUmum: deskripsiUmumTf.text.isNotEmpty ? deskripsiUmumTf.text : null,
        kontak: kontakTf.text.isNotEmpty ? kontakTf.text : null,
        kesadaran: kesadaranTf.text.isNotEmpty ? kesadaranTf.text : null,
        orientasi: orientasiTf.text.isNotEmpty ? orientasiTf.text : null,
        memori: memoriTf.text.isNotEmpty ? memoriTf.text : null,
        konsentrasi: konsentrasiTf.text.isNotEmpty ? konsentrasiTf.text : null,
        mood: moodTf.text.isNotEmpty ? moodTf.text : null,
        prosesBerpikir: prosesBerpikirTf.text.isNotEmpty ? prosesBerpikirTf.text : null,
        persepsi: persepsiTf.text.isNotEmpty ? persepsiTf.text : null,
        kemauan: kemauanTf.text.isNotEmpty ? kemauanTf.text : null,
        psikomotor: psikomotorTf.text.isNotEmpty ? psikomotorTf.text : null,
        intelegensi: intelegensiTf.text.isNotEmpty ? intelegensiTf.text : null,
        diagnosis: diagnosisTf.text,
        terapi: terapiTf.text,
        note: noteTf.text,
        pasienId: pasienId,
        isActive: true,
        createdBy: createdBy ?? "system",
      );

      await KunjunganRepo.insert(kunjungan);
      await loadKunjunganByPasienId(pasienId);
      clearForm();
      return true;
    } catch (e) {
      _errorMessage = "Gagal menambahkan kunjungan: $e";
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateKunjungan(String modifiedBy) async {
    try {
      if (_selectedKunjungan == null) return false;
      
      final kunjungan = KunjunganModel(
        kunjunganId: _selectedKunjungan!.kunjunganId,
        tanggalKunjungan: _tanggalKunjungan ?? DateTime.now(),
        keluhanUtama: keluhanUtamaTf.text,
        riwayatPenyakitSekarang: riwayatSekarangTf.text,
        riwayatPenyakitDahulu: riwayatDahuluTf.text,
        riwayatPenyakitKeluarga: riwayatKeluargaTf.text,
        pemeriksaanFisik: pemeriksaanFisikTf.text,
        tekananDarah: tekananDarahTf.text,
        suhu: suhuTf.text,
        skalaNyeri: skalaNyeriTf.text,
        nadi: nadiTf.text.isNotEmpty ? nadiTf.text : null,
        respirationRate: respirationRateTf.text.isNotEmpty ? respirationRateTf.text : null,
        deskripsiUmum: deskripsiUmumTf.text.isNotEmpty ? deskripsiUmumTf.text : null,
        kontak: kontakTf.text.isNotEmpty ? kontakTf.text : null,
        kesadaran: kesadaranTf.text.isNotEmpty ? kesadaranTf.text : null,
        orientasi: orientasiTf.text.isNotEmpty ? orientasiTf.text : null,
        memori: memoriTf.text.isNotEmpty ? memoriTf.text : null,
        konsentrasi: konsentrasiTf.text.isNotEmpty ? konsentrasiTf.text : null,
        mood: moodTf.text.isNotEmpty ? moodTf.text : null,
        prosesBerpikir: prosesBerpikirTf.text.isNotEmpty ? prosesBerpikirTf.text : null,
        persepsi: persepsiTf.text.isNotEmpty ? persepsiTf.text : null,
        kemauan: kemauanTf.text.isNotEmpty ? kemauanTf.text : null,
        psikomotor: psikomotorTf.text.isNotEmpty ? psikomotorTf.text : null,
        intelegensi: intelegensiTf.text.isNotEmpty ? intelegensiTf.text : null,
        diagnosis: diagnosisTf.text,
        terapi: terapiTf.text,
        note: noteTf.text,
        pasienId: _selectedKunjungan!.pasienId,
        isActive: true,
        createDate: _selectedKunjungan!.createDate,
        createdBy: _selectedKunjungan!.createdBy,
        modifiedBy: modifiedBy,
        modifyDate: DateTime.now(),
      );

      await KunjunganRepo.update(kunjungan);
      await loadKunjunganByPasienId(_selectedKunjungan!.pasienId);
      clearForm();
      return true;
    } catch (e) {
      _errorMessage = "Gagal mengupdate kunjungan: $e";
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteKunjungan(String kunjunganId, String pasienId) async {
    try {
      await KunjunganRepo.delete(kunjunganId, createdBy ?? "system");
      await loadKunjunganByPasienId(pasienId);
      return true;
    } catch (e) {
      _errorMessage = "Gagal menghapus kunjungan: $e";
      notifyListeners();
      return false;
    }
  }

  void setSelectedKunjungan(KunjunganModel kunjungan) {
    _selectedKunjungan = kunjungan;
    _tanggalKunjungan = kunjungan.tanggalKunjungan;
    keluhanUtamaTf.text = kunjungan.keluhanUtama;
    riwayatSekarangTf.text = kunjungan.riwayatPenyakitSekarang;
    riwayatDahuluTf.text = kunjungan.riwayatPenyakitDahulu;
    riwayatKeluargaTf.text = kunjungan.riwayatPenyakitKeluarga;
    pemeriksaanFisikTf.text = kunjungan.pemeriksaanFisik;
    tekananDarahTf.text = kunjungan.tekananDarah;
    suhuTf.text = kunjungan.suhu;
    skalaNyeriTf.text = kunjungan.skalaNyeri;
    nadiTf.text = kunjungan.nadi ?? '';
    respirationRateTf.text = kunjungan.respirationRate ?? '';

    deskripsiUmumTf.text = kunjungan.deskripsiUmum ?? '';
    kontakTf.text = kunjungan.kontak ?? '';
    kesadaranTf.text = kunjungan.kesadaran ?? '';
    orientasiTf.text = kunjungan.orientasi ?? '';
    memoriTf.text = kunjungan.memori ?? '';
    konsentrasiTf.text = kunjungan.konsentrasi ?? '';
    moodTf.text = kunjungan.mood ?? '';
    prosesBerpikirTf.text = kunjungan.prosesBerpikir ?? '';
    persepsiTf.text = kunjungan.persepsi ?? '';
    kemauanTf.text = kunjungan.kemauan ?? '';
    psikomotorTf.text = kunjungan.psikomotor ?? '';
    intelegensiTf.text = kunjungan.intelegensi ?? '';
    
    diagnosisTf.text = kunjungan.diagnosis;
    terapiTf.text = kunjungan.terapi;
    noteTf.text = kunjungan.note ?? '';
    notifyListeners();
  }

  void setTanggalKunjungan(DateTime date) {
    _tanggalKunjungan = date;
    notifyListeners();
  }

  void clearForm() {
    _selectedKunjungan = null;
    _tanggalKunjungan = DateTime.now();
    keluhanUtamaTf.clear();
    riwayatSekarangTf.clear();
    riwayatDahuluTf.clear();
    riwayatKeluargaTf.clear();
    pemeriksaanFisikTf.clear();
    tekananDarahTf.clear();
    suhuTf.clear();
    skalaNyeriTf.clear();
    nadiTf.clear();
    respirationRateTf.clear();

    deskripsiUmumTf.clear();
    kontakTf.clear();
    kesadaranTf.clear();
    orientasiTf.clear();
    memoriTf.clear();
    konsentrasiTf.clear();
    moodTf.clear();
    prosesBerpikirTf.clear();
    persepsiTf.clear();
    kemauanTf.clear();
    psikomotorTf.clear();
    intelegensiTf.clear();
    
    diagnosisTf.clear();
    terapiTf.clear();
    noteTf.clear();
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
  }