import 'package:uuid/uuid.dart';

import 'model_converters.dart';

class KunjunganModel {
  String kunjunganId;
  DateTime tanggalKunjungan;
  String keluhanUtama;
  String riwayatPenyakitSekarang;
  String riwayatPenyakitDahulu;
  String riwayatPenyakitKeluarga;
  String pemeriksaanFisik;
  String tekananDarah;
  String suhu;
  String skalaNyeri;
  // Opsional (bukan required seperti tekananDarah/suhu/skalaNyeri di atas):
  // ditambahkan belakangan, dan kunjungan lama yang sudah tersimpan tidak
  // punya nilai untuk kolom ini.
  String? nadi;
  String? respirationRate;

  String? deskripsiUmum;
  String? kontak;
  String? kesadaran;
  String? orientasi;
  String? memori;
  String? konsentrasi;
  String? mood;
  String? prosesBerpikir;
  String? persepsi;
  String? kemauan;
  String? psikomotor;
  String? intelegensi;
  
  String diagnosis;
  String terapi;
  String? note;
  String pasienId;
  bool isActive;
  DateTime createDate;
  String createdBy;
  DateTime? modifyDate;
  String? modifiedBy;

  KunjunganModel({
    String? kunjunganId,
    required this.tanggalKunjungan,
    required this.keluhanUtama,
    required this.riwayatPenyakitSekarang,
    required this.riwayatPenyakitDahulu,
    required this.riwayatPenyakitKeluarga,
    required this.pemeriksaanFisik,
    required this.tekananDarah,
    required this.suhu,
    required this.skalaNyeri,
    this.nadi,
    this.respirationRate,
    this.deskripsiUmum,
    this.kontak,
    this.kesadaran,
    this.orientasi,
    this.memori,
    this.konsentrasi,
    this.mood,
    this.prosesBerpikir,
    this.persepsi,
    this.kemauan,
    this.psikomotor,
    this.intelegensi,
    required this.diagnosis,
    required this.terapi,
    this.note,
    required this.pasienId,
    required this.isActive,
    DateTime? createDate,
    required this.createdBy,
    this.modifyDate,
    this.modifiedBy,
  })  : kunjunganId = kunjunganId ?? const Uuid().v4(),
        createDate = createDate ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'kunjungan_id': kunjunganId,
      'tanggal_kunjungan': dateToJson(tanggalKunjungan),
      'keluhan_utama': keluhanUtama,
      'riwayat_penyakit_sekarang': riwayatPenyakitSekarang,
      'riwayat_penyakit_dahulu': riwayatPenyakitDahulu,
      'riwayat_penyakit_keluarga': riwayatPenyakitKeluarga,
      'pemeriksaan_fisik': pemeriksaanFisik,
      'tekanan_darah': tekananDarah,
      'suhu': suhu,
      'skala_nyeri': skalaNyeri,
      'nadi': nadi,
      'respiration_rate': respirationRate,
      'deskripsi_umum': deskripsiUmum,
      'kontak': kontak,
      'kesadaran': kesadaran,
      'orientasi': orientasi,
      'memori': memori,
      'konsentrasi': konsentrasi,
      'mood': mood,
      'proses_berpikir': prosesBerpikir,
      'persepsi': persepsi,
      'kemauan': kemauan,
      'psikomotor': psikomotor,
      'intelegensi': intelegensi,
      'diagnosis': diagnosis,
      'terapi': terapi,
      'note': note,
      'pasien_id': pasienId,
      'is_active': isActive,
      'create_date': timestampToJson(createDate),
      'created_by': createdBy,
      'modify_date': timestampToJsonOrNull(modifyDate),
      'modified_by': modifiedBy,
    };
  }

  factory KunjunganModel.fromMap(Map<String, dynamic> map) {
    return KunjunganModel(
      kunjunganId: asString(map['kunjungan_id']),
      tanggalKunjungan: asDate(map['tanggal_kunjungan']),
      keluhanUtama: asString(map['keluhan_utama']),
      riwayatPenyakitSekarang: asString(map['riwayat_penyakit_sekarang']),
      riwayatPenyakitDahulu: asString(map['riwayat_penyakit_dahulu']),
      riwayatPenyakitKeluarga: asString(map['riwayat_penyakit_keluarga']),
      pemeriksaanFisik: asString(map['pemeriksaan_fisik']),
      tekananDarah: asString(map['tekanan_darah']),
      suhu: asString(map['suhu']),
      skalaNyeri: asString(map['skala_nyeri']),
      nadi: asStringOrNull(map['nadi']),
      respirationRate: asStringOrNull(map['respiration_rate']),
      deskripsiUmum: asStringOrNull(map['deskripsi_umum']),
      kontak: asStringOrNull(map['kontak']),
      kesadaran: asStringOrNull(map['kesadaran']),
      orientasi: asStringOrNull(map['orientasi']),
      memori: asStringOrNull(map['memori']),
      konsentrasi: asStringOrNull(map['konsentrasi']),
      mood: asStringOrNull(map['mood']),
      prosesBerpikir: asStringOrNull(map['proses_berpikir']),
      persepsi: asStringOrNull(map['persepsi']),
      kemauan: asStringOrNull(map['kemauan']),
      psikomotor: asStringOrNull(map['psikomotor']),
      intelegensi: asStringOrNull(map['intelegensi']),
      diagnosis: asString(map['diagnosis']),
      terapi: asString(map['terapi']),
      note: asStringOrNull(map['note']),
      pasienId: asString(map['pasien_id']),
      isActive: asBool(map['is_active']),
      createDate: asDateTime(map['create_date']),
      createdBy: asString(map['created_by']),
      modifyDate: asDateTimeOrNull(map['modify_date']),
      modifiedBy: asStringOrNull(map['modified_by']),
    );
  }
}