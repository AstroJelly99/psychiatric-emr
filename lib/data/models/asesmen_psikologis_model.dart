import 'package:uuid/uuid.dart';

import 'model_converters.dart';

class AsesmenPsikologisModel {
  String asesmenId;
  String jenisAsesmen;
  int skorTotal;
  String hasilInterpretasi;
  String pasienId;
  String kunjunganId;
  String instrumenId;
  DateTime? tanggalAsesmen;
  bool isActive;
  DateTime createDate;
  String createdBy;
  DateTime? modifyDate;
  String? modifiedBy;

  AsesmenPsikologisModel({
    String? asesmenId,
    required this.jenisAsesmen,
    required this.skorTotal,
    required this.hasilInterpretasi,
    required this.pasienId,
    required this.kunjunganId,
    required this.instrumenId,
    this.tanggalAsesmen,
    required this.isActive,
    DateTime? createDate,
    required this.createdBy,
    this.modifyDate,
    this.modifiedBy,
  })  : asesmenId = asesmenId ?? const Uuid().v4(),
        createDate = createDate ?? DateTime.now();

  factory AsesmenPsikologisModel.fromMap(Map<String, dynamic> map) {
    return AsesmenPsikologisModel(
      asesmenId: asString(map['asesmen_id']),
      jenisAsesmen: asString(map['jenis_asesmen']),
      skorTotal: asInt(map['skor_total']),
      hasilInterpretasi: asString(map['hasil_interpretasi']),
      pasienId: asString(map['pasien_id']),
      kunjunganId: asString(map['kunjungan_id']),
      instrumenId: asString(map['instrumen_id']),
      tanggalAsesmen: asDateTimeOrNull(map['tanggal_asesmen']),
      isActive: asBool(map['is_active']),
      createDate: asDateTime(map['create_date']),
      createdBy: asString(map['created_by']),
      modifyDate: asDateTimeOrNull(map['modify_date']),
      modifiedBy: asStringOrNull(map['modified_by']),
    );
  }
}
