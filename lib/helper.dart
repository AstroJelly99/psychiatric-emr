import 'package:flutter/material.dart';
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
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 900, maxHeight: 700),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, provider),
                const SizedBox(height: 16),
                Expanded(
                  child: _buildContent(provider),
                ),
                const SizedBox(height: 16),
                _buildActions(context, provider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, DrugInteractionProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Drug-Drug Interaction Checker',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: blueDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Powered by OpenFDA API & Local Database',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }

  Widget _buildContent(DrugInteractionProvider provider) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildDrugInputs(provider),
          const SizedBox(height: 16),
          _buildResults(provider),
        ],
      ),
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
              'Enter Drug Names (Maximum 5):',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
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
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
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

    Map<String, List<dynamic>> groupedInteractions = _groupInteractionsByPair(provider.results);

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
                style: TextStyle(fontSize: 14, height: 1.4, color: Colors.grey[800]),
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
                  Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Drug Interaction Results:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...groupedInteractions.entries
                  .map((entry) => _buildInteractionPairCard(entry.key, entry.value))
                  ,
            ],
          ],
        ),
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
                Icon(Icons.medication_outlined, color: Colors.orange[700], size: 20),
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
                      child: Text(drugInfo.drugName),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, List<dynamic>> _groupInteractionsByPair(List<DrugInteractionResult> results) {
    Map<String, List<dynamic>> grouped = {};
    Set<String> processedInteractions = {};

    for (var result in results) {
      for (var cross in result.crossInteractions) {
        String pairKey = _createPairKey(cross.drug1, cross.drug2);
        String interactionKey = '$pairKey|${cross.description.hashCode}';

        if (!processedInteractions.contains(interactionKey)) {
          grouped.putIfAbsent(pairKey, () => []);
          grouped[pairKey]!.add(cross);
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3), width: 2),
        borderRadius: BorderRadius.circular(8),
        color: Colors.orange.withValues(alpha: 0.05),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(pairKey.toUpperCase()),
      ),
    );
  }

  Widget _buildActions(BuildContext context, DrugInteractionProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (provider.results.isNotEmpty)
          Text(
            '${provider.results.length} drug(s) analyzed',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        const Spacer(),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Close'),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: provider.isLoading ? null : () => provider.checkInteractions(),
          style: ElevatedButton.styleFrom(
            backgroundColor: blueHighlight,
            foregroundColor: Colors.black,
          ),
          child: provider.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.black),
                  ),
                )
              : const Text('Check Interactions'),
        ),
      ],
    );
  }
}

// ========== WIDGET AUTOCOMPLETE UNTUK DRUG INPUT ==========

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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                          const Icon(Icons.medication, size: 18, color: Colors.blue),
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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