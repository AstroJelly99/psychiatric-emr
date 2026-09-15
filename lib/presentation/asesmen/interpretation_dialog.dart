import 'package:flutter/material.dart';
import 'package:emr_homemade/FBBlock/sk_block.dart';
import 'package:emr_homemade/domain/instrumen/interpretation_rule_provider.dart';
import 'package:provider/provider.dart';

class InterpretationRulesDialog extends StatefulWidget {
  final String instrumenId;
  final String instrumenName;

  const InterpretationRulesDialog({
    super.key,
    required this.instrumenId,
    required this.instrumenName,
  });

  @override
  State<InterpretationRulesDialog> createState() =>
      _InterpretationRulesDialogState();
}

class _InterpretationRulesDialogState extends State<InterpretationRulesDialog> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => InterpretationRuleProvider(
        context,
        widget.instrumenId,
      ),
      child: Consumer<InterpretationRuleProvider>(
        builder: (context, prov, _) {
          final Size screen = MediaQuery.of(context).size;
          final bool narrow = screen.width < 640;
          final double inset = narrow ? 12 : 40;

          return Dialog(
            insetPadding:
                EdgeInsets.symmetric(horizontal: inset, vertical: 24),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: (screen.width - inset * 2).clamp(0.0, 900.0),
                maxHeight: screen.height * (narrow ? 0.9 : 0.85),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.orange.shade600, Colors.orange.shade400],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.rule, color: Colors.white, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Atur Interpretasi",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                widget.instrumenName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: prov.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildAddRuleSection(prov),
                                const SizedBox(height: 24),
                                const Divider(),
                                const SizedBox(height: 16),
                                _buildRulesList(prov),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddRuleSection(InterpretationRuleProvider prov) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Tambah Aturan Baru",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SkBlock.lineWrap(
            responsive: true,
            spacing: 12,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              TextField(
                controller: prov.minScoreController,
                decoration: const InputDecoration(
                  labelText: "Skor Minimum",
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: prov.maxScoreController,
                decoration: const InputDecoration(
                  labelText: "Skor Maksimum",
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: prov.labelController,
                decoration: const InputDecoration(
                  labelText: "Label Interpretasi",
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  await prov.addRule();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.all(16),
                ),
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRulesList(InterpretationRuleProvider prov) {
    if (prov.rules.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Text("Belum ada aturan interpretasi"),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Daftar Aturan Interpretasi",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...prov.rules.map((rule) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "#${rule.ruleOrder}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rule.interpretationLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Skor: ${rule.minScore} - ${rule.maxScore}",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    await prov.deleteRule(rule.ruleId);
                  },
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}