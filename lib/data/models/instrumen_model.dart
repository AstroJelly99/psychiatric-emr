import 'package:uuid/uuid.dart';

import 'model_converters.dart';

class InstrumenModel {
  String instrumenId;
  String versi;
  String namaInstrumen;
  String deskripsi;
  bool isActive;
  DateTime createDate;
  String createdBy;
  DateTime? modifyDate;
  String? modifiedBy;

  InstrumenModel({
  String? instrumenId,
    required this.versi,
    required this.namaInstrumen,
    required this.deskripsi,
    required this.isActive,
    DateTime? createDate,
    required this.createdBy,
    this.modifyDate,
    this.modifiedBy,
  })  : instrumenId = instrumenId ?? const Uuid().v4(),
        createDate = createDate ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'instrumen_id': instrumenId,
        'versi': versi,
        'nama_instrumen': namaInstrumen,
        'deskripsi': deskripsi,
        'is_active': isActive,
        'create_date': timestampToJson(createDate),
        'created_by': createdBy,
        'modify_date': timestampToJsonOrNull(modifyDate),
        'modified_by': modifiedBy,
      };

  factory InstrumenModel.fromMap(Map<String, dynamic> map) {
    return InstrumenModel(
      instrumenId: asString(map['instrumen_id']),
      versi: asString(map['versi']),
      namaInstrumen: asString(map['nama_instrumen']),
      deskripsi: asString(map['deskripsi']),
      isActive: asBool(map['is_active']),
      createDate: asDateTime(map['create_date']),
      createdBy: asString(map['created_by']),
      modifyDate: asDateTimeOrNull(map['modify_date']),
      modifiedBy: asStringOrNull(map['modified_by']),
    );
  }
}
