import 'package:flutter/material.dart';
import 'package:emr_homemade/FBBlock/sk_block.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:emr_homemade/domain/drug_interaction/drug_interaction_provider.dart';
import 'package:emr_homemade/utils/widgets/constant.dart';
import 'package:provider/provider.dart';
import 'package:emr_homemade/data/repositories/obat_repo.dart';

class DrugInteractionDialog extends StatelessWidget {
  const DrugInteractionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DrugInteractionProvider>(
      builder: (context, provider, child) {
        // Tanpa insetPadding sendiri, Dialog memakai bawaan Material 40px per
        // sisi: di 360dp isinya tinggal 280px, lalu dipotong lagi padding 24
        // per sisi jadi 232px. Itu sebabnya dialog ini terasa "kecil dan
        // terhimpit" padahal isinya panjang.
        final Size screen = MediaQuery.of(context).size;
        final bool narrow = screen.width < SkBlock.compactBreakpoint;
        final double inset = narrow ? 12 : 40;

        return Dialog(
          insetPadding:
              EdgeInsets.symmetric(horizontal: inset, vertical: 24),
          clipBehavior: Clip.antiAlias,
          backgroundColor: Colors.grey.shade100,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 900,
              maxHeight: screen.height * (narrow ? 0.9 : 0.85),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context, provider, narrow),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(narrow ? 14 : 24),
                    child: _buildContent(provider),
                  ),
                ),
                _buildActions(context, provider, narrow),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(
      BuildContext context, DrugInteractionProvider provider, bool narrow) {
    return Container(
      padding: EdgeInsets.fromLTRB(narrow ? 16 : 24, 14, 8, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [blueDark, blueHighlight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SkBlock.sectionHeader(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        leading: const Icon(Icons.compare_arrows_rounded,
            color: Colors.white, size: 26),
        // Judul panjang ini sebelumnya terpotong jadi "Drug-Drug Interactio…".
        // Dua baris diizinkan supaya terbaca utuh.
        title: 'Cek Interaksi Antar Obat',
        titleMaxLines: 2,
        titleStyle: const TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        subtitle: 'Sumber: OpenFDA API & basis data lokal',
        subtitleStyle: TextStyle(
          fontSize: 13,
          color: Colors.white.withValues(alpha: 0.85),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 26),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
    );
  }

  Widget _buildContent(DrugInteractionProvider provider) {
    // SingleChildScrollView-nya sudah dipindah ke pemanggil supaya padding
    // ikut menggulung dan tidak ada scroll bersarang.
    return Column(
      children: [
        _buildDrugInputs(provider),
        const SizedBox(height: 16),
        _buildResults(provider),
      ],
    );
  }

  Widget _buildDrugInputs(DrugInteractionProvider provider) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan nama obat (maksimal 5)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            const SizedBox(height: 12),
            ...List<Widget>.generate(provider.drugs.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: DrugAutocompleteField(
                        initialValue: provider.drugs[index],
                        index: index,
                        onChanged: (value) => provider.updateDrug(index, value),
                      ),
                    ),
                    if (provider.drugs.length > 1)
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline,
                            color: Colors.red),
                        onPressed: () => provider.removeDrug(index),
                      ),
                  ],
                ),
              );
            }),
            if (provider.drugs.length < 5)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: ElevatedButton.icon(
                  onPressed: provider.addDrug,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Another Drug'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: blueSec,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(DrugInteractionProvider provider) {
    if (provider.isLoading) {
      return const Center(
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Analyzing drug interactions...',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            Text(
              'This may take a few moments',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (provider.errorMessage.isNotEmpty && provider.results.isEmpty) {
      return Card(
        elevation: 2,
        color: Colors.red[50],
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[700], size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Error Occurred',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[700],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                provider.errorMessage,
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 12),
              const Text(
                'Please try again or contact support if the problem persists.',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.results.isEmpty && provider.notFoundDrugs.isEmpty) {
      return const SizedBox();
    }

    final notFoundDrugs = provider.notFoundDrugs;
    final hasNotFoundDrugs = notFoundDrugs.isNotEmpty;

    Map<String, List<dynamic>> groupedInteractions =
        _groupInteractionsByPair(provider.results);

    if (groupedInteractions.isEmpty && !hasNotFoundDrugs) {
      return Card(
        elevation: 2,
        color: Colors.blue[50],
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.search_off, color: Colors.blue[700], size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No Interactions Found',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'No documented drug-drug interactions were identified between the specified medications in our database.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.amber[800], size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: Colors.grey[800],
                          ),
                          children: [
                            TextSpan(
                              text: 'Database Limitation: ',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.amber[900],
                              ),
                            ),
                            const TextSpan(
                              text:
                                  'This system may not capture all possible interactions. '
                                  'Cross-reference with additional clinical resources and '
                                  'consider patient-specific factors (renal/hepatic function, '
                                  'age, comorbidities) before prescribing.',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasNotFoundDrugs) ...[
              _buildNotFoundDrugsCard(notFoundDrugs),
              const SizedBox(height: 16),
            ],
            if (groupedInteractions.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.orange[700], size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Drug Interaction Results:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...groupedInteractions.entries
                  .map((entry) =>
                      _buildInteractionPairCard(entry.key, entry.value))
                  ,
              const SizedBox(height: 16),
              _buildDisclaimerFooter(),
            ] else if (!hasNotFoundDrugs) ...[
              Row(
                children: [
                  Icon(Icons.search_off, color: Colors.blue[700], size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'No Interactions Found',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'No documented interactions identified. Verify with additional clinical resources.',
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDisclaimerFooter() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.medical_information_outlined,
              color: Colors.grey[600], size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'System may not capture all interactions. Verify with additional references and assess patient-specific risk factors.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFoundDrugsCard(List<DrugNotFoundInfo> notFoundDrugs) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3), width: 2),
        borderRadius: BorderRadius.circular(8),
        color: Colors.orange.withValues(alpha: 0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.medication_outlined,
                    color: Colors.orange[700], size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Drug Information Not Found',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'We could not find information for the following drugs in our databases:',
                  style: TextStyle(fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 12),
                ...notFoundDrugs.map((drugInfo) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.medication,
                                  size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  drugInfo.drugName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (drugInfo.errorMessage != null) ...[
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.warning_amber,
                                    size: 14, color: Colors.red[600]),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    drugInfo.errorMessage!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.red[700],
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (drugInfo.suggestedName != null) ...[
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.lightbulb_outline,
                                    size: 14, color: Colors.blue[600]),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Did you mean: ${drugInfo.suggestedName}?',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue[700],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    )),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline,
                          size: 16, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Troubleshooting tips:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue[700],
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              '• Check the spelling of the drug name\n'
                              '• Try using the generic name instead of brand name\n'
                              '• Ensure your internet connection is stable\n'
                              '• The drug may not be in our database yet',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, List<dynamic>> _groupInteractionsByPair(
      List<DrugInteractionResult> results) {
    Map<String, List<dynamic>> grouped = {};
    Set<String> processedInteractions = {};

    for (var result in results) {
      debugPrint('\n🔄 Processing result for: ${result.drugName}');

      for (var cross in result.crossInteractions) {
        String pairKey = _createPairKey(cross.drug1, cross.drug2);
        String interactionKey = '$pairKey|${cross.description.hashCode}';

        if (!processedInteractions.contains(interactionKey)) {
          grouped.putIfAbsent(pairKey, () => []);
          grouped[pairKey]!.add(cross);
          processedInteractions.add(interactionKey);
        }
      }

      for (var interaction in result.localInteractions) {
        String pairKey =
            _createPairKey(result.drugName, interaction.interactsWith);
        String interactionKey = '$pairKey|${interaction.description.hashCode}';

        if (!processedInteractions.contains(interactionKey)) {
          grouped.putIfAbsent(pairKey, () => []);
          grouped[pairKey]!.add(MapEntry(result.drugName, interaction));
          processedInteractions.add(interactionKey);
        }
      }

      for (var interaction in result.openFdaInteractions) {
        String pairKey =
            _createPairKey(result.drugName, interaction.interactsWith);
        String interactionKey = '$pairKey|${interaction.description.hashCode}';

        if (!processedInteractions.contains(interactionKey)) {
          grouped.putIfAbsent(pairKey, () => []);
          grouped[pairKey]!.add(MapEntry(result.drugName, interaction));
          processedInteractions.add(interactionKey);
        }
      }
    }

    return grouped;
  }

  String _createPairKey(String drug1, String drug2) {
    List<String> pair = [drug1.toLowerCase(), drug2.toLowerCase()]..sort();
    return pair.join(' + ');
  }

  Widget _buildInteractionPairCard(String pairKey, List<dynamic> interactions) {
    if (interactions.isEmpty) return const SizedBox();

    debugPrint('\n🎨 Building card for: $pairKey');

    InteractionSeverity? highestSeverity;

    for (var interaction in interactions) {
      InteractionSeverity? severity;

      if (interaction is CrossDrugInteraction) {
        severity = interaction.severity;
        debugPrint('  CrossInteraction severity: $severity');
      } else if (interaction is MapEntry) {
        final value = interaction.value;
        if (value is ParsedInteraction) {
          severity = value.severity;
          debugPrint('  MapEntry (ParsedInteraction) severity: $severity');
        } else {
          debugPrint(
              '  ⚠️ MapEntry value is not ParsedInteraction: ${value.runtimeType}');
        }
      } else {
        debugPrint('  ⚠️ Unknown interaction type: ${interaction.runtimeType}');
      }

      if (severity == null || severity == InteractionSeverity.unknown) {
        debugPrint('  ⏭️ Skipping unknown severity');
        continue;
      }

      if (highestSeverity == null) {
        highestSeverity = severity;
        debugPrint('  🎯 Initial severity set to: $severity');
      } else {
        if (severity.index < highestSeverity.index) {
          debugPrint(
              '  🔄 Updating highest severity from $highestSeverity to $severity');
          highestSeverity = severity;
        }
      }
    }

    highestSeverity ??= InteractionSeverity.unknown;

    debugPrint('  🏆 Final highest severity for $pairKey: $highestSeverity');

    Color severityColor = _getSeverityColor(highestSeverity);
    String severityLabel = _getSeverityLabel(highestSeverity);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: severityColor.withValues(alpha: 0.3), width: 2),
        borderRadius: BorderRadius.circular(8),
        color: severityColor.withValues(alpha: 0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: severityColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.medication, color: severityColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    pairKey.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: severityColor,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: severityColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    severityLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: interactions.map((interaction) {
                String description = '';
                String source = '';
                InteractionSeverity itemSeverity = InteractionSeverity.unknown;

                if (interaction is CrossDrugInteraction) {
                  description = interaction.description;
                  source = interaction.source;
                  itemSeverity = interaction.severity;
                } else if (interaction is MapEntry) {
                  final value = interaction.value;
                  if (value is ParsedInteraction) {
                    description = value.description;
                    source = value.source;
                    itemSeverity = value.severity;
                  }
                }

                Color itemColor = _getSeverityColor(itemSeverity);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Icon(Icons.info_outline,
                            size: 16, color: itemColor),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              description,
                              // 16px: ini paragraf klinis panjang yang dibaca
                              // utuh, bukan label. 13px terlalu kecil untuk
                              // dibaca di layar HP.
                              style: const TextStyle(fontSize: 16, height: 1.55),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    'Sumber: $source',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: itemColor.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _getSeverityLabel(itemSeverity),
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: itemColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(InteractionSeverity severity) {
    switch (severity) {
      case InteractionSeverity.major:
        return Colors.red[700]!;
      case InteractionSeverity.moderate:
        return Colors.orange[700]!;
      case InteractionSeverity.minor:
        return Colors.blue[700]!;
      case InteractionSeverity.unknown:
        return Colors.grey[700]!;
    }
  }

  String _getSeverityLabel(InteractionSeverity severity) {
    switch (severity) {
      case InteractionSeverity.major:
        return 'MAJOR';
      case InteractionSeverity.moderate:
        return 'MODERATE';
      case InteractionSeverity.minor:
        return 'MINOR';
      case InteractionSeverity.unknown:
        return 'UNKNOWN';
    }
  }

  Widget _buildActions(
      BuildContext context, DrugInteractionProvider provider, bool narrow) {
    // Dulu satu Row: keterangan "N drug(s) analyzed" + Spacer + dua tombol.
    // Label "Check Interactions" saja sudah ±150px, jadi setelah hasil muncul
    // barisnya melewati dialog 102px. Sekarang keterangan berdiri sendiri di
    // atas, dan tombolnya menumpuk lewat lineWrap.
    return Container(
      padding: EdgeInsets.all(narrow ? 14 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (provider.results.isNotEmpty) ...[
            Text(
              '${provider.results.length} obat dianalisis',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 10),
          ],
          SkBlock.lineWrap(
            responsive: true,
            spacing: 10,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  side: BorderSide(color: Colors.grey.shade400),
                ),
                child: Text('TUTUP',
                    style: GoogleFonts.nunito(
                        fontSize: 15, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                onPressed:
                    provider.isLoading ? null : () => provider.checkInteractions(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: blueHighlight,
                  foregroundColor: Colors.black,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: provider.isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.black),
                        ),
                      )
                    : Text('CEK INTERAKSI',
                        style: GoogleFonts.nunito(
                            fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DrugAutocompleteField extends StatefulWidget {
  final String initialValue;
  final int index;
  final Function(String) onChanged;

  const DrugAutocompleteField({
    super.key,
    required this.initialValue,
    required this.index,
    required this.onChanged,
  });

  @override
  State<DrugAutocompleteField> createState() => _DrugAutocompleteFieldState();
}

class _DrugAutocompleteFieldState extends State<DrugAutocompleteField> {
  late TextEditingController _controller;
  List<String> _suggestions = [];
  bool _showSuggestions = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _removeOverlay();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _searchDrugs(String query) async {
    if (query.length < 2) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      _removeOverlay();
      return;
    }

    try {
      final results = await ObatRepo.searchNamaObatSuggestions(query);

      setState(() {
        _suggestions = results;
        _showSuggestions = _suggestions.isNotEmpty;
      });

      if (_showSuggestions) {
        _showOverlay();
      } else {
        _removeOverlay();
      }
    } catch (e) {
      debugPrint('Error searching drugs: $e');
    }
  }

  void _showOverlay() {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: _getSuggestionBoxWidth(),
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, _controller.text.isEmpty ? 56 : 60),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  return InkWell(
                    onTap: () {
                      _controller.text = _suggestions[index];
                      widget.onChanged(_suggestions[index]);
                      _removeOverlay();
                      setState(() {
                        _showSuggestions = false;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: index < _suggestions.length - 1
                                ? Colors.grey.shade200
                                : Colors.transparent,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.medication,
                              size: 18, color: Colors.blue),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _suggestions[index],
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  double _getSuggestionBoxWidth() {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    return renderBox?.size.width ?? 300;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: _controller,
        onChanged: (value) {
          widget.onChanged(value);
          _searchDrugs(value);
        },
        onTap: () {
          if (_controller.text.length >= 2) {
            _searchDrugs(_controller.text);
          }
        },
        decoration: InputDecoration(
          labelText: 'Drug ${widget.index + 1}',
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          prefixIcon: const Icon(Icons.medication, size: 20),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    _controller.clear();
                    widget.onChanged('');
                    _removeOverlay();
                    setState(() {
                      _suggestions = [];
                      _showSuggestions = false;
                    });
                  },
                )
              : null,
        ),
      ),
    );
  }
}
