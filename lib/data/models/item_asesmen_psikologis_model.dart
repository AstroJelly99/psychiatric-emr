import 'model_converters.dart';

class ItemAsesmenPsikologisModel {
  int itemId;
  int skor;
  String asesmenId;
  String instrumenItemId;
  bool isActive;
  DateTime createDate;
  String createdBy;
  DateTime? modifyDate;
  String? modifiedBy;

  ItemAsesmenPsikologisModel({
    int? itemId,
    required this.skor,
    required this.asesmenId,
    required this.instrumenItemId,
    required this.isActive,
    DateTime? createDate,
    required this.createdBy,
    this.modifyDate,
    this.modifiedBy,
  })  : itemId = itemId ?? 0,
        createDate = createDate ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'item_id': itemId,
        'skor': skor,
        'asesmen_id': asesmenId,
        'instrumen_item_id': instrumenItemId,
        'is_active': isActive,
        'create_date': timestampToJson(createDate),
        'created_by': createdBy,
        'modify_date': timestampToJsonOrNull(modifyDate),
        'modified_by': modifiedBy,
      };

  factory ItemAsesmenPsikologisModel.fromMap(Map<String, dynamic> map) {
    return ItemAsesmenPsikologisModel(
      itemId: asInt(map['item_id']),
      skor: asInt(map['skor']),
      asesmenId: asString(map['asesmen_id']),
      instrumenItemId: asString(map['instrumen_item_id']),
      isActive: asBool(map['is_active']),
      createDate: asDateTime(map['create_date']),
      createdBy: asString(map['created_by']),
      modifyDate: asDateTimeOrNull(map['modify_date']),
      modifiedBy: asStringOrNull(map['modified_by']),
    );
  }
}
