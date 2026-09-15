import 'package:uuid/uuid.dart';

import 'model_converters.dart';

class InstrumenItemModel {
  String instrumenItemId;
  String instrumenId; // Tambahkan field ini
  String pertanyaan;
  String teksPertanyaan;
  int nomerItem;
  String kategoriSkoring;
  bool isActive;
  DateTime createDate;
  String createdBy;
  DateTime? modifyDate;
  String? modifiedBy;

  InstrumenItemModel({
    String? instrumenItemId,
    required this.instrumenId, // Tambahkan parameter ini
    required this.pertanyaan,
    required this.teksPertanyaan,
    required this.nomerItem,
    required this.kategoriSkoring,
    required this.isActive,
    DateTime? createDate,
    required this.createdBy,
    this.modifyDate,
    this.modifiedBy,
  })  : instrumenItemId = instrumenItemId ?? const Uuid().v4(),
        createDate = createDate ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'instrumen_item_id': instrumenItemId,
      'instrumen_id': instrumenId, // Tambahkan field ini
      'pertanyaan': pertanyaan,
      'teks_pertanyaan': teksPertanyaan,
      'nomer_item': nomerItem,
      'kategori_skoring': kategoriSkoring,
      'is_active': isActive,
      'create_date': timestampToJson(createDate),
      'created_by': createdBy,
      'modify_date': timestampToJsonOrNull(modifyDate),
      'modified_by': modifiedBy,
    };
  }

  factory InstrumenItemModel.fromMap(Map<String, dynamic> map) {
    return InstrumenItemModel(
      instrumenItemId: asString(map['instrumen_item_id']),
      instrumenId: asString(map['instrumen_id']),
      pertanyaan: asString(map['pertanyaan']),
      teksPertanyaan: asString(map['teks_pertanyaan']),
      nomerItem: asInt(map['nomer_item']),
      kategoriSkoring: asString(map['kategori_skoring']),
      isActive: asBool(map['is_active']),
      createDate: asDateTime(map['create_date']),
      createdBy: asString(map['created_by']),
      modifyDate: asDateTimeOrNull(map['modify_date']),
      modifiedBy: asStringOrNull(map['modified_by']),
    );
  }

   List<int> get skoringOptions {
    final range = kategoriSkoring.split('-');
    if (range.length != 2) return [0, 1, 2, 3, 4]; // default
    
    final start = int.tryParse(range[0]) ?? 0;
    final end = int.tryParse(range[1]) ?? 4;
    
    return List.generate(end - start + 1, (index) => start + index);
  }
}