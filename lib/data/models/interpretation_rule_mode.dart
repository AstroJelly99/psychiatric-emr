import 'package:uuid/uuid.dart';

import 'model_converters.dart';

class InterpretationRuleModel {
  String ruleId;
  String instrumenId;
  int minScore;
  int maxScore;
  String interpretationLabel;
  int ruleOrder;
  bool isActive;
  DateTime createDate;
  String createdBy;
  DateTime? modifyDate;
  String? modifiedBy;

  InterpretationRuleModel({
    String? ruleId,
    required this.instrumenId,
    required this.minScore,
    required this.maxScore,
    required this.interpretationLabel,
    required this.ruleOrder,
    required this.isActive,
    DateTime? createDate,
    required this.createdBy,
    this.modifyDate,
    this.modifiedBy,
  })  : ruleId = ruleId ?? const Uuid().v4(),
        createDate = createDate ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'rule_id': ruleId,
        'instrumen_id': instrumenId,
        'min_score': minScore,
        'max_score': maxScore,
        'interpretation_label': interpretationLabel,
        'rule_order': ruleOrder,
        'is_active': isActive,
        'create_date': timestampToJson(createDate),
        'created_by': createdBy,
        'modify_date': timestampToJsonOrNull(modifyDate),
        'modified_by': modifiedBy,
      };

  factory InterpretationRuleModel.fromMap(Map<String, dynamic> map) {
    return InterpretationRuleModel(
      ruleId: asString(map['rule_id']),
      instrumenId: asString(map['instrumen_id']),
      minScore: asInt(map['min_score']),
      maxScore: asInt(map['max_score']),
      interpretationLabel: asString(map['interpretation_label']),
      ruleOrder: asInt(map['rule_order']),
      isActive: asBool(map['is_active']),
      createDate: asDateTime(map['create_date']),
      createdBy: asString(map['created_by']),
      modifyDate: asDateTimeOrNull(map['modify_date']),
      modifiedBy: asStringOrNull(map['modified_by']),
    );
  }
}