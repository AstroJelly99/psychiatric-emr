import 'package:uuid/uuid.dart';

import 'model_converters.dart';

class ResepModel {
  String resepId;
  DateTime tanggalResep;
  String catatan;
  String pasienId;
  String kunjunganId;
  bool isActive;
  DateTime createDate;
  String createdBy;
  DateTime? modifyDate;
  String? modifiedBy;

  ResepModel({
    String? resepId,
    required this.tanggalResep,
    required this.catatan,
    required this.pasienId,
    required this.kunjunganId,
    required this.isActive,
    DateTime? createDate,
    required this.createdBy,
    this.modifyDate,
    this.modifiedBy,
  })  : resepId = resepId ?? const Uuid().v4(),
        createDate = createDate ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'resep_id': resepId,
        'tanggal_resep': dateToJson(tanggalResep),
        'catatan': catatan,
        'pasien_id': pasienId,
        'kunjungan_id': kunjunganId,
        'is_active': isActive,
        'create_date': timestampToJson(createDate),
        'created_by': createdBy,
        'modify_date': timestampToJsonOrNull(modifyDate),
        'modified_by': modifiedBy,
      };

  factory ResepModel.fromMap(Map<String, dynamic> map) {
    return ResepModel(
      resepId: asString(map['resep_id']),
      tanggalResep: asDate(map['tanggal_resep']),
      catatan: asString(map['catatan']),
      pasienId: asString(map['pasien_id']),
      kunjunganId: asString(map['kunjungan_id']),
      isActive: asBool(map['is_active']),
      createDate: asDateTime(map['create_date']),
      createdBy: asString(map['created_by']),
      modifyDate: asDateTimeOrNull(map['modify_date']),
      modifiedBy: asStringOrNull(map['modified_by']),
    );
  }


  ResepModel copyWith({
    String? resepId,
    DateTime? tanggalResep,
    String? catatan,
    String? pasienId,
    String? kunjunganId,
    bool? isActive,
    DateTime? createDate,
    String? createdBy,
    DateTime? modifyDate,
    String? modifiedBy,
  }) {
    return ResepModel(
      resepId: resepId ?? this.resepId,
      tanggalResep: tanggalResep ?? this.tanggalResep,
      catatan: catatan ?? this.catatan,
      pasienId: pasienId ?? this.pasienId,
      kunjunganId: kunjunganId ?? this.kunjunganId,
      isActive: isActive ?? this.isActive,
      createDate: createDate ?? this.createDate,
      createdBy: createdBy ?? this.createdBy,
      modifyDate: modifyDate ?? this.modifyDate,
      modifiedBy: modifiedBy ?? this.modifiedBy,
    );
  }
}


