import 'package:flutter/material.dart';
import 'package:emr_homemade/data/models/interpretation_rule_mode.dart';
import 'package:emr_homemade/data/repositories/interpretation_rule_repo.dart';
import 'package:shared_preferences/shared_preferences.dart';


class InterpretationRuleProvider with ChangeNotifier {
  InterpretationRuleProvider(this.context, this.instrumenId) {
    loadPreferences();
    loadRules();
  }

  final BuildContext context;
  final String instrumenId;

  bool isLoading = false;
  String? createdBy;
  List<InterpretationRuleModel> rules = [];

  TextEditingController minScoreController = TextEditingController();
  TextEditingController maxScoreController = TextEditingController();
  TextEditingController labelController = TextEditingController();

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    createdBy = prefs.getString('username') ?? 'system';
    notifyListeners();
  }

  Future<void> loadRules() async {
    _setLoading(true);
    try {
      rules = await InterpretationRuleRepo.getByInstrumenId(instrumenId);
    } catch (e) {
      debugPrint("Error loading rules: $e");
    }
    _setLoading(false);
  }

  Future<void> addRule() async {
    if (minScoreController.text.isEmpty ||
        maxScoreController.text.isEmpty ||
        labelController.text.isEmpty) {
      return;
    }

    try {
      final rule = InterpretationRuleModel(
        instrumenId: instrumenId,
        minScore: int.parse(minScoreController.text),
        maxScore: int.parse(maxScoreController.text),
        interpretationLabel: labelController.text,
        ruleOrder: rules.length + 1,
        isActive: true,
        createdBy: createdBy ?? 'system',
      );

      await InterpretationRuleRepo.insert(rule);

      minScoreController.clear();
      maxScoreController.clear();
      labelController.clear();

      await loadRules();
    } catch (e) {
      debugPrint("Error adding rule: $e");
    }
  }

  Future<void> deleteRule(String ruleId) async {
    try {
      await InterpretationRuleRepo.delete(ruleId, createdBy ?? 'system');
      await loadRules();
    } catch (e) {
      debugPrint("Error deleting rule: $e");
    }
  }

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    minScoreController.dispose();
    maxScoreController.dispose();
    labelController.dispose();
    super.dispose();
  }
}