import 'package:flutter/material.dart';
import 'package:emr_homemade/domain/drug_interaction/drug_interaction_provider.dart';
import 'package:emr_homemade/presentation/drug_interaction/drug_interaction_dialog.dart';
import 'package:provider/provider.dart';

class DrugInteractionManager extends StatelessWidget {
  const DrugInteractionManager({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DrugInteractionProvider>(
      builder: (context, provider, child) {
        if (provider.showDialog) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const DrugInteractionDialog(),
            );
          });
        }
        return const SizedBox.shrink();
      },
    );
  }
}