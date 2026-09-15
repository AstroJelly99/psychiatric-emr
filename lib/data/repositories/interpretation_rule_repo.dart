import 'package:emr_homemade/data/models/interpretation_rule_mode.dart';

import '../models/model_converters.dart';
import '../../database/database_helper.dart';

class InterpretationRuleRepo {
  static const String _table = 'instrumen_interpretation_rules';

  static Future<List<InterpretationRuleModel>> getByInstrumenId(
      String instrumenId) {
    return DatabaseHelper.run('getByInstrumenId interpretation_rule', () async {
      final rows = await DatabaseHelper.table(_table)
          .select()
          .eq('instrumen_id', instrumenId)
          .eq('is_active', true)
          .order('rule_order', ascending: true);
      return rows.map((row) => InterpretationRuleModel.fromMap(row)).toList();
    });
  }

  static Future<String> getInterpretation(String instrumenId, int totalScore) {
    return DatabaseHelper.run('getInterpretation interpretation_rule',
        () async {
      // `? BETWEEN min_score AND max_score` -> dua filter kolom:
      // min_score <= totalScore <= max_score.
      final row = await DatabaseHelper.table(_table)
          .select('interpretation_label')
          .eq('instrumen_id', instrumenId)
          .eq('is_active', true)
          .lte('min_score', totalScore)
          .gte('max_score', totalScore)
          .order('rule_order', ascending: true)
          .limit(1)
          .maybeSingle();

      if (row != null) {
        return asString(row['interpretation_label']);
      }

      return "Unknown";
    });
  }

  static Future<void> insert(InterpretationRuleModel rule) {
    return DatabaseHelper.run('insert interpretation_rule', () async {
      await DatabaseHelper.table(_table).insert({
        'rule_id': rule.ruleId,
        'instrumen_id': rule.instrumenId,
        'min_score': rule.minScore,
        'max_score': rule.maxScore,
        'interpretation_label': rule.interpretationLabel,
        'rule_order': rule.ruleOrder,
        'is_active': rule.isActive,
        'create_date': timestampToJson(rule.createDate),
        'created_by': rule.createdBy,
      });
    });
  }

  static Future<void> update(InterpretationRuleModel rule) {
    return DatabaseHelper.run('update interpretation_rule', () async {
      await DatabaseHelper.table(_table).update({
        'min_score': rule.minScore,
        'max_score': rule.maxScore,
        'interpretation_label': rule.interpretationLabel,
        'rule_order': rule.ruleOrder,
        'is_active': rule.isActive,
        'modify_date': timestampToJson(DateTime.now()),
        'modified_by': rule.modifiedBy,
      }).eq('rule_id', rule.ruleId);
    });
  }

  static Future<void> delete(String ruleId, String modifiedBy) {
    return DatabaseHelper.run('delete interpretation_rule', () async {
      await DatabaseHelper.table(_table).update({
        'is_active': false,
        'modify_date': timestampToJson(DateTime.now()),
        'modified_by': modifiedBy,
      }).eq('rule_id', ruleId);
    });
  }

  static Future<List<InterpretationRuleModel>> getAll() {
    return DatabaseHelper.run('getAll interpretation_rule', () async {
      final rows = await DatabaseHelper.table(_table)
          .select()
          .eq('is_active', true)
          .order('instrumen_id', ascending: true)
          .order('rule_order', ascending: true);
      return rows.map((row) => InterpretationRuleModel.fromMap(row)).toList();
    });
  }
}
