import 'package:uuid/uuid.dart';

import 'model_converters.dart';

class ObatModel {
  String obatId;
  String namaObat;
  String? namaGenerik;
  String kategori;
  String? deskripsi;
  bool isActive;
  DateTime createDate;
  String createdBy;
  DateTime? modifyDate;
  String? modifiedBy;

  ObatModel({
    String? obatId,
    required this.namaObat,
    this.namaGenerik,
    required this.kategori,
    this.deskripsi,
    required this.isActive,
    DateTime? createDate,
    required this.createdBy,
    this.modifyDate,
    this.modifiedBy,
  })  : obatId = obatId ?? const Uuid().v4(),
        createDate = createDate ?? DateTime.now();


  Map<String, dynamic> toMap() => {
        'obat_id': obatId,
        'nama_obat': namaObat,
        'nama_generik': namaGenerik,
        'kategori': kategori,
        'deskripsi': deskripsi,
        'is_active': isActive,
        'create_date': timestampToJson(createDate),
        'created_by': createdBy,
        'modify_date': timestampToJsonOrNull(modifyDate),
        'modified_by': modifiedBy,
      };

  // Helper konversi Blob (Uint8List) dari mysql1 sudah dihapus: kolom
  // `deskripsi` yang bertipe TEXT dulu datang sebagai Uint8List dan harus
  // di-utf8.decode; lewat PostgREST semuanya sudah String.
  factory ObatModel.fromMap(Map<String, dynamic> map) {
    return ObatModel(
      obatId: asString(map['obat_id']),
      namaObat: asString(map['nama_obat']),
      namaGenerik: asStringOrNull(map['nama_generik']),
      kategori: asString(map['kategori']),
      deskripsi: asStringOrNull(map['deskripsi']),
      isActive: asBool(map['is_active']),
      createDate: asDateTime(map['create_date']),
      createdBy: asString(map['created_by']),
      modifyDate: asDateTimeOrNull(map['modify_date']),
      modifiedBy: asStringOrNull(map['modified_by']),
    );
  }
}

/// Tingkat keparahan interaksi obat.
///
/// Urutan deklarasi HARUS sama persis dengan enum `severity_level` di
/// Postgres (0001_init.sql), karena `ORDER BY severity_level DESC` pada
/// enum native mengurutkan berdasarkan urutan deklarasi, bukan alfabet.
///
/// Nama konstanta sengaja HURUF BESAR — nilainya dipetakan langsung ke nilai
/// enum di database lewat `.name` dan `.byName()`, jadi mengubahnya jadi
/// lowerCamelCase akan memutus pemetaan itu.
///
/// CONTRAINDICATED ditambahkan setelah migrasi: kolomnya sudah punya nilai ini
/// sejak versi MySQL, tapi enum Dart hanya memuat tiga nilai, sehingga baris
/// CONTRAINDICATED jatuh ke fallback dan tampil sebagai MODERATE tanpa error
/// apa pun — interaksi paling berbahaya justru yang paling diremehkan.
// ignore_for_file: constant_identifier_names
enum SeverityLevel {
  MINOR,
  MODERATE,
  MAJOR,
  CONTRAINDICATED
}
class DrugInteractionModel {
  String interactionId;
  String obatId1;
  String obatId2;
  String namaObat1;    
  String namaObat2;     
  SeverityLevel severityLevel;
  String deskripsiInteraksi;
  bool isActive;
  DateTime createDate;
  String createdBy;
  DateTime? modifyDate;
  String? modifiedBy;

  DrugInteractionModel({
    String? interactionId,
    required this.obatId1,
    required this.obatId2,
    this.namaObat1 = '',
    this.namaObat2 = '',
    required this.severityLevel,
    required this.deskripsiInteraksi,
    required this.isActive,
    DateTime? createDate,
    required this.createdBy,
    this.modifyDate,
    this.modifiedBy,
  })  : interactionId = interactionId ?? const Uuid().v4(),
        createDate = createDate ?? DateTime.now();

  /// Payload kolom tabel `drug_interaction`.
  ///
  /// `nama_obat_1` / `nama_obat_2` sengaja TIDAK disertakan: keduanya alias
  /// hasil JOIN, bukan kolom tabel. Versi lama memancarkannya dan akan
  /// ditolak PostgREST dengan "column does not exist" kalau map ini dipakai
  /// sebagai payload insert.
  Map<String, dynamic> toMap() => {
        'interaction_id': interactionId,
        'obat_id_1': obatId1,
        'obat_id_2': obatId2,
        'severity_level': severityLevel.name,
        'deskripsi_interaksi': deskripsiInteraksi,
        'is_active': isActive,
        'create_date': timestampToJson(createDate),
        'created_by': createdBy,
        'modify_date': timestampToJsonOrNull(modifyDate),
        'modified_by': modifiedBy,
      };

  /// Convert dari Map (database / API) ke object Dart.
  ///
  /// Tetap membaca `nama_obat_1` / `nama_obat_2` yang datar. Hasil embedded
  /// select PostgREST berbentuk bersarang, jadi ObatRepo yang meratakannya
  /// dulu sebelum memanggil factory ini — bentuk map yang diterima model
  /// tidak berubah dibanding versi mysql1.
  factory DrugInteractionModel.fromMap(Map<String, dynamic> map) {
    SeverityLevel parseSeverityLevel(dynamic value) {
      final stringValue = asStringOrNull(value) ?? 'MODERATE';
      try {
        return SeverityLevel.values.byName(stringValue);
      } catch (e) {
        return SeverityLevel.MODERATE;
      }
    }

    return DrugInteractionModel(
      interactionId: asString(map['interaction_id']),
      obatId1: asString(map['obat_id_1']),
      obatId2: asString(map['obat_id_2']),
      namaObat1: asString(map['nama_obat_1']),
      namaObat2: asString(map['nama_obat_2']),
      severityLevel: parseSeverityLevel(map['severity_level']),
      deskripsiInteraksi: asString(map['deskripsi_interaksi']),
      isActive: asBool(map['is_active']),
      createDate: asDateTime(map['create_date']),
      createdBy: asString(map['created_by']),
      modifyDate: asDateTimeOrNull(map['modify_date']),
      modifiedBy: asStringOrNull(map['modified_by']),
    );
  }
}
