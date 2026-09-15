import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:emr_homemade/data/repositories/obat_repo.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

int min(int a, int b) => a < b ? a : b;

class DrugInteractionProvider with ChangeNotifier {
  bool _showDialog = false;
  List<String> _drugs = [''];
  List<DrugInteractionResult> _results = [];
  bool _isLoading = false;
  String _errorMessage = '';

  List<DrugNotFoundInfo> _notFoundDrugs = [];

  bool get showDialog => _showDialog;
  List<String> get drugs => _drugs;
  List<DrugInteractionResult> get results => _results;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  List<DrugNotFoundInfo> get notFoundDrugs => _notFoundDrugs;

  void setShowDialog(bool value) {
    _showDialog = value;
    if (!value) reset();
    notifyListeners();
  }

  void updateDrug(int index, String value) {
    if (index < _drugs.length) {
      _drugs[index] = value;
      notifyListeners();
    }
  }

  void addDrug() {
    if (_drugs.length < 5) {
      _drugs.add('');
      notifyListeners();
    }
  }

  void removeDrug(int index) {
    if (_drugs.length > 1) {
      _drugs.removeAt(index);
      notifyListeners();
    }
  }

  Future<void> checkInteractions() async {
    _isLoading = true;
    _errorMessage = '';
    _notFoundDrugs = [];
    notifyListeners();

    _results = [];

    final validDrugs = _drugs.where((drug) => drug.trim().isNotEmpty).toList();

    if (validDrugs.isEmpty) {
      _errorMessage = 'Please enter at least 1 drug';
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      Map<String, EnhancedDrugData> drugDataMap = {};

      for (String drug in validDrugs) {
        try {
          EnhancedDrugData data =
              await _fetchEnhancedDrugData(drug, validDrugs);
          drugDataMap[drug.toLowerCase()] = data;

          if (!data.foundInAnyDatabase) {
            String? suggestion = await _getDrugNameSuggestion(drug);

            _notFoundDrugs.add(DrugNotFoundInfo(
              drugName: drug,
              foundInLocal: data.foundInLocal,
              foundInOpenFda: data.foundInOpenFda,
              suggestedName: suggestion,
            ));

            debugPrint('⚠️ Drug not found in any database: $drug');
          } else {
            debugPrint(
                '✅ Drug found: $drug (Local: ${data.foundInLocal}, OpenFDA: ${data.foundInOpenFda})');
          }
        } catch (e) {
          debugPrint('❌ Error fetching data for drug "$drug": $e');
          _notFoundDrugs.add(DrugNotFoundInfo(
            drugName: drug,
            foundInLocal: false,
            foundInOpenFda: false,
            errorMessage:
                'Failed to fetch data: ${_getReadableErrorMessage(e)}',
          ));
        }
      }

      if (drugDataMap.isEmpty) {
        _errorMessage =
            'Unable to fetch data for any of the entered drugs. Please check your internet connection and drug names.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      List<CrossDrugInteraction> crossInteractions =
          _analyzeSmartCrossInteractionsOptimized(validDrugs, drugDataMap);

      for (String drug in validDrugs) {
        if (drugDataMap.containsKey(drug.toLowerCase())) {
          EnhancedDrugData data = drugDataMap[drug.toLowerCase()]!;

          List<CrossDrugInteraction> relevantCross = crossInteractions
              .where((ci) =>
                  ci.drug1.toLowerCase() == drug.toLowerCase() ||
                  ci.drug2.toLowerCase() == drug.toLowerCase())
              .toList();

          _results.add(DrugInteractionResult(
            drugName: drug,
            localInteractions: data.localInteractions,
            openFdaInteractions: data.openFdaInteractions,
            crossInteractions: relevantCross,
            generalWarnings: data.generalWarnings,
            hasData: data.hasData,
          ));
        }
      }

      if (_notFoundDrugs.isNotEmpty) {
        debugPrint(
            'ℹ️ ${_notFoundDrugs.length} drug(s) not found in databases');
      }
    } on SocketException catch (e) {
      _errorMessage =
          'Network error: Please check your internet connection and try again.';
      debugPrint('❌ SocketException in checkInteractions: $e');
    } on TimeoutException catch (e) {
      _errorMessage =
          'Request timeout: The server took too long to respond. Please try again.';
      debugPrint('❌ TimeoutException in checkInteractions: $e');
    } on FormatException catch (e) {
      _errorMessage =
          'Data format error: Unable to process response from server.';
      debugPrint('❌ FormatException in checkInteractions: $e');
    } catch (e) {
      _errorMessage =
          'An unexpected error occurred: ${_getReadableErrorMessage(e)}';
      debugPrint('❌ Error in checkInteractions: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  String _getReadableErrorMessage(dynamic error) {
    if (error is SocketException) {
      return 'Network connection failed';
    } else if (error is TimeoutException) {
      return 'Request timed out';
    } else if (error is FormatException) {
      return 'Invalid data format';
    } else if (error is http.ClientException) {
      return 'HTTP request failed';
    } else {
      return error.toString();
    }
  }

  Future<EnhancedDrugData> _fetchEnhancedDrugData(
      String drugName, List<String> allDrugs) async {
    List<ParsedInteraction> localInteractions = [];
    List<ParsedInteraction> openFdaInteractions = [];
    List<String> generalWarnings = [];

    bool foundInLocal = false;
    bool foundInOpenFda = false;

    try {
      try {
        var localResult =
            await _checkLocalDatabaseWithStatus(drugName, allDrugs);
        localInteractions = localResult.interactions;
        foundInLocal = localResult.drugFound;
        debugPrint(
            '✅ Local database check completed for $drugName (Found: $foundInLocal)');
      } catch (e) {
        debugPrint('⚠️ Error checking local database for $drugName: $e');
      }

      try {
        var openFdaResult = await _checkOpenFdaWithStatus(drugName, allDrugs);
        openFdaInteractions = openFdaResult.interactions;
        foundInOpenFda = openFdaResult.drugFound;
        debugPrint(
            '✅ OpenFDA check completed for $drugName (Found: $foundInOpenFda)');
      } catch (e) {
        debugPrint('⚠️ Error checking OpenFDA for $drugName: $e');
      }

      try {
        generalWarnings = await _getGeneralWarnings(drugName);
        debugPrint('✅ General warnings check completed for $drugName');
      } catch (e) {
        debugPrint('⚠️ Error getting general warnings for $drugName: $e');
      }
    } catch (e) {
      debugPrint('❌ Error in _fetchEnhancedDrugData for $drugName: $e');
    }

    bool hasData = localInteractions.isNotEmpty ||
        openFdaInteractions.isNotEmpty ||
        generalWarnings.isNotEmpty;

    bool foundInAnyDatabase = foundInLocal || foundInOpenFda;

    return EnhancedDrugData(
      localInteractions: localInteractions,
      openFdaInteractions: openFdaInteractions,
      generalWarnings: generalWarnings,
      hasData: hasData,
      foundInLocal: foundInLocal,
      foundInOpenFda: foundInOpenFda,
      foundInAnyDatabase: foundInAnyDatabase,
    );
  }

  List<CrossDrugInteraction> _analyzeSmartCrossInteractionsOptimized(
      List<String> drugs, Map<String, EnhancedDrugData> drugDataMap) {
    List<CrossDrugInteraction> crossInteractions = [];
    Set<String> processedPairs = {};

    for (int i = 0; i < drugs.length; i++) {
      for (int j = i + 1; j < drugs.length; j++) {
        String drug1 = drugs[i].toLowerCase();
        String drug2 = drugs[j].toLowerCase();

        String pairKey = ([drug1, drug2]..sort()).join('_');
        if (processedPairs.contains(pairKey)) continue;
        processedPairs.add(pairKey);

        debugPrint('\n🔍 Analyzing pair: ${drugs[i]} + ${drugs[j]}');

        List<CrossDrugInteraction> pairInteractions = [];

        if (!drugDataMap.containsKey(drug1) ||
            !drugDataMap.containsKey(drug2)) {
          debugPrint(
              '⚠️ Skipping pair - one or both drugs not found in data map');
          continue;
        }

        EnhancedDrugData data1 = drugDataMap[drug1]!;
        for (var interaction in data1.localInteractions) {
          if (_isMatchingDrug(interaction.interactsWith, drug2) ||
              _isMatchingDrug(drug2, interaction.interactsWith)) {
            pairInteractions.add(CrossDrugInteraction(
              drug1: drugs[i],
              drug2: drugs[j],
              description: interaction.description,
              severity: interaction.severity,
              source: 'Local Database',
            ));
          }
        }

        for (var interaction in data1.openFdaInteractions) {
          if (_isMatchingDrug(interaction.interactsWith, drug2)) {
            pairInteractions.add(CrossDrugInteraction(
              drug1: drugs[i],
              drug2: drugs[j],
              description: interaction.description,
              severity: interaction.severity,
              source: 'OpenFDA',
            ));
          }
        }

        EnhancedDrugData data2 = drugDataMap[drug2]!;
        for (var interaction in data2.openFdaInteractions) {
          if (_isMatchingDrug(interaction.interactsWith, drug1)) {
            pairInteractions.add(CrossDrugInteraction(
              drug1: drugs[j],
              drug2: drugs[i],
              description: interaction.description,
              severity: interaction.severity,
              source: 'OpenFDA',
            ));
          }
        }

        debugPrint(
            '📦 Found ${pairInteractions.length} interactions for this pair');

        if (pairInteractions.isNotEmpty) {
          pairInteractions.sort((a, b) =>
              _severityRank(b.severity).compareTo(_severityRank(a.severity)));

          List<CrossDrugInteraction> uniqueInteractions =
              _smartDeduplication(pairInteractions);

          crossInteractions.addAll(uniqueInteractions);

          debugPrint(
              '✅ After deduplication: ${uniqueInteractions.length} unique interactions');
        }
      }
    }

    debugPrint('📊 Total cross-interactions: ${crossInteractions.length}');
    return crossInteractions;
  }

  List<CrossDrugInteraction> _smartDeduplication(
      List<CrossDrugInteraction> interactions) {
    if (interactions.isEmpty) return [];

    List<CrossDrugInteraction> unique = [];
    Set<String> seenDescriptionHashes = {};

    Map<String, List<CrossDrugInteraction>> bySource = {};
    for (var interaction in interactions) {
      bySource.putIfAbsent(interaction.source, () => []).add(interaction);
    }

    for (var source in bySource.keys) {
      var sourceInteractions = bySource[source]!;

      for (var interaction in sourceInteractions) {
        String contentHash = _createSemanticHash(interaction.description);

        bool isUnique = true;
        for (var existingHash in seenDescriptionHashes) {
          if (_areSemanticallyDuplicate(contentHash, existingHash)) {
            var existing = unique.firstWhere(
                (e) => _createSemanticHash(e.description) == existingHash);

            if (_severityRank(interaction.severity) >
                _severityRank(existing.severity)) {
              unique.remove(existing);
              seenDescriptionHashes.remove(existingHash);
            } else {
              isUnique = false;
            }
            break;
          }
        }

        if (isUnique && unique.length < 5) {
          unique.add(interaction);
          seenDescriptionHashes.add(contentHash);
        }
      }
    }

    return unique;
  }

  String _createSemanticHash(String description) {
    String normalized = description.toLowerCase().trim();

    List<String> fillers = [
      'the',
      'a',
      'an',
      'in',
      'on',
      'at',
      'to',
      'for',
      'of',
      'with',
      'is',
      'was',
      'are',
      'were',
      'be',
      'been',
      'being',
      'have',
      'has',
      'had',
      'do',
      'does',
      'did',
      'can',
      'could',
      'may',
      'might',
      'should',
      'would'
    ];

    List<String> words = normalized.split(RegExp(r'\s+'));
    List<String> keywords =
        words.where((w) => !fillers.contains(w) && w.length > 3).toList();

    keywords.sort();
    return keywords.take(15).join('|');
  }

  bool _areSemanticallyDuplicate(String hash1, String hash2) {
    if (hash1 == hash2) return true;

    Set<String> words1 = hash1.split('|').toSet();
    Set<String> words2 = hash2.split('|').toSet();

    if (words1.isEmpty || words2.isEmpty) return false;

    int intersection = words1.intersection(words2).length;
    int union = words1.union(words2).length;

    double similarity = union > 0 ? intersection / union : 0.0;

    return similarity > 0.75;
  }

  bool _isMatchingDrug(String drugA, String drugB) {
    if (drugA.isEmpty || drugB.isEmpty) return false;

    String a = drugA.toLowerCase().trim();
    String b = drugB.toLowerCase().trim();

    if (a == b) return true;

    if (a.length >= 4 && b.length >= 4) {
      if (a.startsWith(b) || b.startsWith(a)) return true;
    }

    if (a.length >= 6 && b.length >= 6) {
      if (a.contains(b) || b.contains(a)) return true;
    }

    List<String> suffixes = [
      'sodium',
      'potassium',
      'calcium',
      'hydrochloride',
      'sulfate',
      'tablets',
      'capsules',
      'injection',
      'oral',
      'hcl',
      'er',
      'xr',
      'sr',
      'chloride',
      'acetate',
      'phosphate',
      'maleate',
      'tartrate'
    ];

    String cleanA = a;
    String cleanB = b;

    for (var suffix in suffixes) {
      cleanA = cleanA
          .replaceAll(' $suffix', '')
          .replaceAll('-$suffix', '')
          .replaceAll('$suffix ', '');
      cleanB = cleanB
          .replaceAll(' $suffix', '')
          .replaceAll('-$suffix', '')
          .replaceAll('$suffix ', '');
    }

    cleanA = cleanA.trim();
    cleanB = cleanB.trim();

    if (cleanA.length >= 4 && cleanB.length >= 4) {
      return cleanA == cleanB ||
          cleanA.startsWith(cleanB) ||
          cleanB.startsWith(cleanA);
    }

    return false;
  }

  Future<DrugCheckResult> _checkOpenFdaWithStatus(
      String drugName, List<String> allInputDrugs) async {
    try {
      final response = await http
          .get(Uri.parse(
              'https://api.fda.gov/drug/label.json?search=openfda.generic_name:"$drugName"&limit=2'))
          .timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException(
              'OpenFDA API request timed out after 15 seconds');
        },
      );

      if (response.statusCode == 200) {
        try {
          Map<String, dynamic> data = json.decode(response.body);

          if (data['results'] != null && data['results'].isNotEmpty) {
            var result = data['results'][0];
            var interactions = _parseOpenFdaInteractionsImproved(
                result, drugName, allInputDrugs);

            return DrugCheckResult(
              interactions: interactions,
              drugFound: true,
            );
          } else {
            debugPrint('ℹ️ Drug not found in OpenFDA database: $drugName');
            return DrugCheckResult(
              interactions: [],
              drugFound: false,
            );
          }
        } on FormatException catch (e) {
          debugPrint('❌ Failed to parse OpenFDA response for $drugName: $e');
          throw const FormatException('Invalid JSON response from OpenFDA API');
        }
      } else if (response.statusCode == 404) {
        debugPrint('ℹ️ Drug not found in OpenFDA (404): $drugName');
        return DrugCheckResult(
          interactions: [],
          drugFound: false,
        );
      } else if (response.statusCode == 429) {
        debugPrint('⚠️ OpenFDA API rate limit exceeded: $drugName');
        throw Exception(
            'OpenFDA API rate limit exceeded. Please try again later.');
      } else if (response.statusCode >= 500) {
        debugPrint(
            '❌ OpenFDA server error (${response.statusCode}): $drugName');
        throw Exception('OpenFDA server error. Please try again later.');
      } else {
        debugPrint('⚠️ OpenFDA API error ${response.statusCode}: $drugName');
        return DrugCheckResult(
          interactions: [],
          drugFound: false,
        );
      }
    } on SocketException catch (e) {
      debugPrint(
          '❌ Network error in _checkOpenFdaWithStatus for $drugName: $e');
      throw SocketException('Failed to connect to OpenFDA API: ${e.message}');
    } on TimeoutException catch (e) {
      debugPrint(
          '❌ Timeout error in _checkOpenFdaWithStatus for $drugName: $e');
      rethrow;
    } on FormatException catch (e) {
      debugPrint('❌ Format error in _checkOpenFdaWithStatus for $drugName: $e');
      rethrow;
    } catch (e) {
      debugPrint(
          '❌ Unexpected error in _checkOpenFdaWithStatus for $drugName: $e');
      return DrugCheckResult(
        interactions: [],
        drugFound: false,
      );
    }
  }

  Future<String?> _getDrugNameSuggestion(String drugName) async {
    try {
      // Dulu dua LIKE di-OR: nama penuh, lalu 4 huruf pertama sebagai
      // pelonggaran. Karena pola pertama selalu tercakup oleh yang kedua,
      // satu pencarian dengan potongan 4 huruf sudah memberi hasil yang sama.
      // LIKE -> ilike, karena Postgres case-sensitive.
      final prefix = drugName.substring(0, min(4, drugName.length));
      var results = await ObatRepo.searchNamaObatSuggestions(prefix, limit: 3);

      if (results.isNotEmpty) {
        return results.first;
      }

      return null;
    } catch (e) {
      debugPrint('⚠️ Error getting drug name suggestion: $e');
      return null;
    }
  }

  List<ParsedInteraction> _parseOpenFdaInteractionsImproved(
      Map<String, dynamic> result,
      String mainDrug,
      List<String> allInputDrugs) {
    List<ParsedInteraction> interactions = [];
    Map<String, ParsedInteraction> interactionMap = {};

    void extractInteractions(List<String>? texts, String sectionType,
        InteractionSeverity defaultSeverity) {
      if (texts == null || texts.isEmpty) return;

      debugPrint('📖 Processing section: $sectionType');

      for (String interactionText in texts) {
        if (interactionText.length < 20) continue;

        List<ParsedInteraction> parsed = _extractFocusedInteractionsImproved(
            interactionText, mainDrug, allInputDrugs,
            defaultSeverity: defaultSeverity);

        for (var p in parsed) {
          String key = p.interactsWith.toLowerCase();

          if (_isRelevantToInputDrugs(p.interactsWith, allInputDrugs)) {
            if (interactionMap.containsKey(key)) {
              var existing = interactionMap[key]!;

              if (_severityRank(p.severity) >
                  _severityRank(existing.severity)) {
                interactionMap[key] = p;
                debugPrint(
                    '   ⬆️ Updated ${p.interactsWith}: ${existing.severity} -> ${p.severity}');
              } else if (_severityRank(p.severity) ==
                  _severityRank(existing.severity)) {
                if (p.description.length > existing.description.length) {
                  interactionMap[key] = p;
                  debugPrint('   📝 Updated with more detailed description');
                }
              }
            } else {
              interactionMap[key] = p;
              debugPrint('   ✅ Added ${p.interactsWith}: ${p.severity}');
            }
          }
        }
      }
    }

    extractInteractions(
        result['contraindications'] != null
            ? List<String>.from(result['contraindications'])
            : null,
        'contraindications',
        InteractionSeverity.major);

    extractInteractions(
        result['drug_interactions'] != null
            ? List<String>.from(result['drug_interactions'])
            : null,
        'drug_interactions',
        InteractionSeverity.moderate);

    extractInteractions(
        result['warnings'] != null
            ? List<String>.from(result['warnings'])
            : null,
        'warnings',
        InteractionSeverity.moderate);

    extractInteractions(
        result['warnings_and_cautions'] != null
            ? List<String>.from(result['warnings_and_cautions'])
            : null,
        'warnings_and_cautions',
        InteractionSeverity.moderate);

    extractInteractions(
        result['precautions'] != null
            ? List<String>.from(result['precautions'])
            : null,
        'precautions',
        InteractionSeverity.moderate);

    extractInteractions(
        result['ask_doctor'] != null
            ? List<String>.from(result['ask_doctor'])
            : null,
        'ask_doctor',
        InteractionSeverity.moderate);

    extractInteractions(
        result['ask_doctor_or_pharmacist'] != null
            ? List<String>.from(result['ask_doctor_or_pharmacist'])
            : null,
        'ask_doctor_or_pharmacist',
        InteractionSeverity.moderate);

    extractInteractions(
        result['clinical_pharmacology'] != null
            ? List<String>.from(result['clinical_pharmacology'])
            : null,
        'clinical_pharmacology',
        InteractionSeverity.moderate);

    interactions = interactionMap.values.toList();

    debugPrint('📊 Total unique interactions: ${interactions.length}');
    return interactions;
  }

  int _severityRank(InteractionSeverity severity) {
    switch (severity) {
      case InteractionSeverity.major:
        return 4;
      case InteractionSeverity.moderate:
        return 3;
      case InteractionSeverity.minor:
        return 2;
      case InteractionSeverity.unknown:
        return 1;
    }
  }

  bool _isRelevantToInputDrugs(String drugName, List<String> allInputDrugs) {
    if (drugName.isEmpty || drugName.length < 3) return false;

    String lowerDrug = drugName.toLowerCase();

    for (String inputDrug in allInputDrugs) {
      if (inputDrug.trim().length < 4) continue;

      if (_isMatchingDrug(lowerDrug, inputDrug.toLowerCase())) {
        debugPrint('✅ "$drugName" is relevant to input "$inputDrug"');
        return true;
      }
    }

    debugPrint('❌ "$drugName" is NOT relevant to any input drugs');
    return false;
  }

  List<ParsedInteraction> _extractFocusedInteractionsImproved(
      String text, String mainDrug, List<String> allInputDrugs,
      {InteractionSeverity defaultSeverity = InteractionSeverity.moderate}) {
    List<ParsedInteraction> interactions = [];

    for (String inputDrug in allInputDrugs) {
      if (inputDrug.toLowerCase() == mainDrug.toLowerCase()) continue;

      if (inputDrug.trim().length < 3) {
        debugPrint('⚠️ Skipping too short drug name: "$inputDrug"');
        continue;
      }

      if (_textMentionsDrug(text, inputDrug) &&
          _isValidDrugMention(text, inputDrug, mainDrug)) {
        String summary = _extractCompleteSentences(text, inputDrug, mainDrug);

        if (summary.isNotEmpty) {
          InteractionSeverity detectedSeverity =
              _detectSeverityFromText(text, mainDrug, inputDrug, summary);

          interactions.add(ParsedInteraction(
            interactsWith: inputDrug,
            description: summary,
            severity: detectedSeverity,
            source: 'OpenFDA',
          ));
        }
      }
    }

    return interactions;
  }

  bool _isValidDrugMention(String text, String drugName, String mainDrug) {
    String lowerText = text.toLowerCase();
    String lowerDrug = drugName.toLowerCase().trim();

    if (lowerDrug.length < 3) return false;

    RegExp wordBoundary = RegExp(r'\b' + RegExp.escape(lowerDrug) + r'\b');
    if (!wordBoundary.hasMatch(lowerText)) return false;

    RegExp extendedMatch = RegExp(r'\w*' + RegExp.escape(lowerDrug) + r'\w+');
    var matches = extendedMatch.allMatches(lowerText);

    for (var match in matches) {
      String fullWord = match.group(0)!;

      if (fullWord != lowerDrug && fullWord.length > lowerDrug.length + 2) {
        debugPrint(
            '⚠️ "$lowerDrug" is part of longer word "$fullWord", skipping');
        return false;
      }
    }

    return true;
  }

  bool _textMentionsDrug(String text, String drugName) {
    if (drugName.trim().length < 3) return false;

    String lowerText = text.toLowerCase();
    String lowerDrug = drugName.toLowerCase().trim();

    RegExp wordBoundary = RegExp(r'\b' + RegExp.escape(lowerDrug) + r'\b');
    return wordBoundary.hasMatch(lowerText);
  }

  String _extractCompleteSentences(String text, String drug1, String drug2) {
    List<String> sentences = text
        .split(RegExp(r'(?<=[.!?])\s+(?=[A-Z])'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && s.length > 10)
        .toList();

    List<ScoredSentence> scoredSentences = [];

    for (int i = 0; i < sentences.length; i++) {
      String sentence = sentences[i];
      int score = 0;
      String lower = sentence.toLowerCase();

      bool mentionsDrug1 = _textMentionsDrug(lower, drug1);
      bool mentionsDrug2 = _textMentionsDrug(lower, drug2);

      if (!mentionsDrug1 && !mentionsDrug2) continue;

      if (mentionsDrug1) score += 10;
      if (mentionsDrug2) score += 10;
      if (mentionsDrug1 && mentionsDrug2) score += 15;

      // High-value keywords
      if (lower.contains('contraindicated')) score += 20;
      if (lower.contains('should not')) score += 18;
      if (lower.contains('do not use')) score += 18;
      if (lower.contains('avoid')) score += 15;
      if (lower.contains('fatal')) score += 15;
      if (lower.contains('severe')) score += 12;
      if (lower.contains('serious')) score += 12;
      if (lower.contains('major bleeding')) score += 12;
      if (lower.contains('hemorrhage')) score += 12;

      // Medium-value keywords
      if (lower.contains('monitor')) score += 8;
      if (lower.contains('caution')) score += 8;
      if (lower.contains('may increase')) score += 7;
      if (lower.contains('may decrease')) score += 7;
      if (lower.contains('adjust dose')) score += 7;
      if (lower.contains('risk')) score += 6;
      if (lower.contains('bleeding')) score += 6;
      if (lower.contains('prothrombin')) score += 8;
      if (lower.contains('inr')) score += 8;

      // Lower-value keywords
      if (lower.contains('increase')) score += 3;
      if (lower.contains('decrease')) score += 3;
      if (lower.contains('may')) score += 2;
      if (lower.contains('effect')) score += 2;

      // Penalties
      if (lower.contains('see') && lower.contains('section')) score -= 5;
      if (lower.contains('refer to')) score -= 3;
      if (lower.length < 30) score -= 2;

      // Bonuses
      if (RegExp(r'\d+%').hasMatch(lower)) score += 4;
      if (RegExp(r'\d+\s*(mg|mcg|g)').hasMatch(lower)) score += 3;

      if (score > 0) {
        scoredSentences.add(ScoredSentence(sentence, score));
      }
    }

    scoredSentences.sort((a, b) => b.score.compareTo(a.score));

    List<String> selectedSentences = [];
    int totalChars = 0;
    int maxChars = 600;

    for (var scoredSent in scoredSentences) {
      if (selectedSentences.length >= 4) break;

      String sentence = scoredSent.sentence;
      int newTotal = totalChars + sentence.length;

      if (newTotal <= maxChars) {
        selectedSentences.add(sentence);
        totalChars = newTotal;
      } else if (selectedSentences.isEmpty) {
        if (sentence.length > maxChars) {
          int lastComma = sentence.lastIndexOf(',', maxChars - 20);
          int lastPeriod = sentence.lastIndexOf('.', maxChars - 20);
          int cutPoint = lastPeriod > lastComma ? lastPeriod : lastComma;

          if (cutPoint > 100) {
            selectedSentences.add(sentence.substring(0, cutPoint + 1));
          } else {
            selectedSentences.add('${sentence.substring(0, maxChars - 3)}...');
          }
        } else {
          selectedSentences.add(sentence);
        }
        break;
      } else {
        break;
      }
    }

    String result = selectedSentences.join(' ');
    result = result.replaceAll(RegExp(r'\s+'), ' ').trim();

    return result;
  }

  InteractionSeverity _detectSeverityFromText(
      String fullText, String drug1, String drug2, String extractedSummary) {
    if (fullText.isEmpty && extractedSummary.isEmpty) {
      return InteractionSeverity.unknown;
    }

    String combinedText = '$fullText $extractedSummary'.toLowerCase();

    if (_isDrugPair(drug1, drug2, 'acetaminophen', 'warfarin')) {
      if (combinedText.contains('monitor') &&
          (combinedText.contains('inr') ||
              combinedText.contains('prothrombin'))) {
        return InteractionSeverity.moderate;
      }
    }

    if (_isDrugPair(drug1, drug2, 'acetaminophen', 'estradiol')) {
      bool hasStrongWarning = combinedText.contains('contraindicated') ||
          combinedText.contains('should not') ||
          combinedText.contains('avoid') ||
          combinedText.contains('serious');

      if (!hasStrongWarning) {
        return InteractionSeverity.minor;
      }
    }

    List<RegExp> majorPatterns = [
      RegExp(r'\bcontraindicated\b'),
      RegExp(r'\bshould not be used\b'),
      RegExp(r'\bdo not use\b'),
      RegExp(r'\bdo not co-?administer\b'),
      RegExp(r'\bavoid\s+concomitant\b'),
      RegExp(r'\bavoid\s+use\b'),
      RegExp(r'\bfatal\b'),
      RegExp(r'\blife-threatening\b'),
      RegExp(r'\bsevere.*bleeding\b'),
      RegExp(r'\bmajor bleeding\b'),
      RegExp(r'\bhemorrhage\b'),
      RegExp(r'\bblack box warning\b'),
    ];

    int majorCount = 0;
    for (var pattern in majorPatterns) {
      if (pattern.hasMatch(combinedText)) {
        majorCount++;
        debugPrint('🔴 MAJOR pattern: $pattern');
      }
    }

    if (majorCount > 0 && !_isJustTableReference(extractedSummary)) {
      return InteractionSeverity.major;
    }

    List<RegExp> moderatePatterns = [
      RegExp(r'\bmonitor\b'),
      RegExp(r'\bcaution\b'),
      RegExp(r'\bask\s+(a\s+)?doctor\b'),
      RegExp(r'\bmay increase\s+risk\b'),
      RegExp(r'\badjust dose\b'),
      RegExp(r'\bcareful\s+monitoring\b'),
      RegExp(r'\bprothrombin\s+time\b'),
      RegExp(r'\binr\b'),
      RegExp(r'\bincreased\s+risk.*bleeding\b'),
    ];

    int moderateCount = 0;
    for (var pattern in moderatePatterns) {
      if (pattern.hasMatch(combinedText)) {
        moderateCount++;
      }
    }

    if (moderateCount >= 2) {
      debugPrint('🟡 MODERATE: $moderateCount indicators');
      return InteractionSeverity.moderate;
    }

    List<RegExp> minorPatterns = [
      RegExp(r'\bminor\b'),
      RegExp(r'\bunlikely\b'),
      RegExp(r'\bweak\b'),
      RegExp(r'\bslight\b'),
      RegExp(r'\bminimal\b'),
    ];

    for (var pattern in minorPatterns) {
      if (pattern.hasMatch(combinedText)) {
        return InteractionSeverity.minor;
      }
    }

    if (moderateCount == 1) {
      return InteractionSeverity.moderate;
    }

    bool mentionsBothDrugs = _textMentionsDrug(combinedText, drug1) &&
        _textMentionsDrug(combinedText, drug2);

    bool hasClinicalKeyword = combinedText.contains('may') ||
        combinedText.contains('decrease') ||
        combinedText.contains('increase') ||
        combinedText.contains('effect');

    if (mentionsBothDrugs && hasClinicalKeyword) {
      return InteractionSeverity.moderate;
    }

    return InteractionSeverity.unknown;
  }

  bool _isDrugPair(String drug1, String drug2, String targetA, String targetB) {
    String d1 = drug1.toLowerCase().trim();
    String d2 = drug2.toLowerCase().trim();
    String ta = targetA.toLowerCase().trim();
    String tb = targetB.toLowerCase().trim();

    return (d1.contains(ta) && d2.contains(tb)) ||
        (d1.contains(tb) && d2.contains(ta));
  }

  bool _isJustTableReference(String text) {
    String lower = text.toLowerCase();
    return lower.contains('table') &&
        lower.length < 100 &&
        !lower.contains('because') &&
        !lower.contains('patient');
  }

  Future<DrugCheckResult> _checkLocalDatabaseWithStatus(
      String drugName, List<String> allInputDrugs) async {
    String toSafeString(dynamic value) {
      if (value == null) return '';
      if (value is String) return value;
      if (value is List<int>) return utf8.decode(value);
      return value.toString();
    }

    try {
      // Dulu: satu query per obat di dalam loop (N+1). Sekarang satu
      // round-trip lewat RPC resolve_drug_names. Aturan penyaringannya sama:
      // input < 3 karakter diabaikan, dan hanya nama yang cocok persis
      // (case-insensitive) yang dianggap ketemu.
      final kandidat = allInputDrugs
          .map((drug) => drug.trim())
          .where((drug) => drug.length >= 3)
          .toList();

      List<String> exactMatchedDrugs =
          await ObatRepo.resolveDrugNames(kandidat);

      for (final drug in kandidat) {
        final ketemu = exactMatchedDrugs
            .any((exact) => exact.toLowerCase() == drug.toLowerCase());
        debugPrint(ketemu
            ? '✅ Exact match found: "$drug"'
            : '⚠️ No exact match for: "$drug"');
      }

      if (exactMatchedDrugs.isEmpty) {
        debugPrint('⚠️ No exact matches found for any input drugs');
        return DrugCheckResult(
          interactions: [],
          drugFound: false,
        );
      }

      // Dulu: WHERE dibangun dengan string concat sepanjang jumlah obat.
      // Sekarang RPC find_interactions_by_drug_names, dengan aturan yang
      // sama — baris ikut terambil kalau CUKUP SATU obatnya ada di daftar,
      // dan penyaringan pasangannya tetap dilakukan di bawah.
      var results = await ObatRepo.findInteractionsByDrugNames(
          exactMatchedDrugs);

      bool drugFound = exactMatchedDrugs
          .any((exact) => exact.toLowerCase() == drugName.toLowerCase());

      if (!drugFound) {
        debugPrint(
            '⚠️ "$drugName" is not an exact match, will be marked as not found');
      }

      List<ParsedInteraction> interactions = [];

      for (var row in results) {
        try {
          String obat1 = toSafeString(row['obat1_name']);
          String obat2 = toSafeString(row['obat2_name']);
          String severityStr = toSafeString(row['severity_level']);
          String description = toSafeString(row['deskripsi_interaksi']);

          if (obat1.isEmpty || obat2.isEmpty) {
            debugPrint('⚠️ Skipping row with empty drug names');
            continue;
          }

          String obat1Lower = obat1.toLowerCase();
          String obat2Lower = obat2.toLowerCase();

          bool obat1IsExactMatch = exactMatchedDrugs
              .any((exact) => exact.toLowerCase() == obat1Lower);
          bool obat2IsExactMatch = exactMatchedDrugs
              .any((exact) => exact.toLowerCase() == obat2Lower);

          if (!obat1IsExactMatch && !obat2IsExactMatch) {
            debugPrint(
                '⚠️ Skipping: Neither "$obat1" nor "$obat2" are exact matches');
            continue;
          }

          bool obat1IsCurrent = obat1Lower == drugName.toLowerCase();
          bool obat2IsCurrent = obat2Lower == drugName.toLowerCase();

          if (!obat1IsCurrent && !obat2IsCurrent) {
            debugPrint(
                '⚠️ Skipping: Current drug "$drugName" not in this interaction pair');
            continue;
          }

          debugPrint('🗄️ Local DB: $obat1 - $obat2, Severity: "$severityStr"');

          String interactsWith = '';
          if (obat1IsCurrent) {
            interactsWith = obat2;
          } else if (obat2IsCurrent) {
            interactsWith = obat1;
          }

          if (interactsWith.isEmpty) continue;

          bool interactsWithIsExactMatch = exactMatchedDrugs.any(
              (exact) => exact.toLowerCase() == interactsWith.toLowerCase());

          if (!interactsWithIsExactMatch) {
            debugPrint(
                '⚠️ Skipping: "$interactsWith" is not an exact match from user input');
            continue;
          }

          InteractionSeverity severity = _parseSeverityLevel(severityStr);

          interactions.add(ParsedInteraction(
            interactsWith: interactsWith,
            description:
                description.isEmpty ? 'No description available' : description,
            severity: severity,
            source: 'Local Database',
          ));

          debugPrint('✅ Added interaction: $drugName ↔ $interactsWith');
        } catch (e) {
          debugPrint('⚠️ Error processing database row: $e');
          continue;
        }
      }

      return DrugCheckResult(
        interactions: interactions,
        drugFound: drugFound,
      );
    } on Exception catch (e) {
      debugPrint(
          '❌ Database error in _checkLocalDatabaseWithStatus for $drugName: $e');
      throw Exception('Failed to access local database: $e');
    } catch (e) {
      debugPrint(
          '❌ Unexpected error in _checkLocalDatabaseWithStatus for $drugName: $e');
      return DrugCheckResult(
        interactions: [],
        drugFound: false,
      );
    }
  }

  InteractionSeverity _parseSeverityLevel(String level) {
    if (level.isEmpty) {
      return InteractionSeverity.moderate;
    }

    String normalized = level.trim().toUpperCase();

    normalized = normalized
        .replaceAll('LEVEL:', '')
        .replaceAll('SEVERITY:', '')
        .replaceAll('INTERACTION:', '')
        .trim();

    if (normalized.contains('CONTRAINDICATED') ||
        normalized == 'MAJOR' ||
        normalized.contains('SEVERE') ||
        normalized.contains('SERIOUS')) {
      return InteractionSeverity.major;
    }

    if (normalized == 'MODERATE' ||
        normalized.contains('MODERATE') ||
        normalized.contains('MEDIUM') ||
        normalized.contains('CAUTION')) {
      return InteractionSeverity.moderate;
    }

    if (normalized == 'MINOR' ||
        normalized.contains('MINOR') ||
        normalized.contains('MILD') ||
        normalized.contains('LOW')) {
      return InteractionSeverity.minor;
    }

    if (RegExp(r'^\d+$').hasMatch(normalized)) {
      int? numLevel = int.tryParse(normalized);
      if (numLevel != null) {
        if (numLevel <= 1) return InteractionSeverity.minor;
        if (numLevel == 2) return InteractionSeverity.moderate;
        return InteractionSeverity.major;
      }
    }

    return InteractionSeverity.moderate;
  }

  Future<List<String>> _getGeneralWarnings(String drugName) async {
    try {
      final response = await http
          .get(Uri.parse(
              'https://api.fda.gov/drug/label.json?search=openfda.generic_name:"$drugName"&limit=2'))
          .timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('General warnings request timed out');
        },
      );

      if (response.statusCode == 200) {
        try {
          Map<String, dynamic> data = json.decode(response.body);

          if (data['results'] != null && data['results'].isNotEmpty) {
            var result = data['results'][0];
            List<String> warnings = [];

            if (result['boxed_warning'] != null) {
              String warning = result['boxed_warning'][0];
              String summary = _summarizeWarning(warning);
              warnings.add('⚠️ BOXED WARNING: $summary');
            }

            return warnings;
          }
        } on FormatException catch (e) {
          debugPrint('❌ Failed to parse warnings response: $e');
          return [];
        }
      }

      return [];
    } on SocketException catch (e) {
      debugPrint('❌ Network error getting warnings for $drugName: $e');
      return [];
    } on TimeoutException catch (e) {
      debugPrint('❌ Timeout getting warnings for $drugName: $e');
      return [];
    } catch (e) {
      debugPrint('⚠️ Error getting warnings for $drugName: $e');
      return [];
    }
  }

  String _summarizeWarning(String warning) {
    List<String> sentences = warning
        .split(RegExp(r'(?<=[.!])\s+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (sentences.isEmpty) {
      return warning.substring(0, 200.clamp(0, warning.length));
    }

    String firstSentence = sentences.first;
    if (firstSentence.length > 250) {
      return '${firstSentence.substring(0, 247)}...';
    }
    return firstSentence;
  }

  void reset() {
    _drugs = [''];
    _results = [];
    _isLoading = false;
    _errorMessage = '';
    _notFoundDrugs = [];
    notifyListeners();
  }
}

class DrugCheckResult {
  final List<ParsedInteraction> interactions;
  final bool drugFound;
  DrugCheckResult({
    required this.interactions,
    required this.drugFound,
  });
}

class DrugNotFoundInfo {
  final String drugName;
  final bool foundInLocal;
  final bool foundInOpenFda;
  final String? suggestedName;
  final String? errorMessage;

  DrugNotFoundInfo({
    required this.drugName,
    required this.foundInLocal,
    required this.foundInOpenFda,
    this.suggestedName,
    this.errorMessage,
  });
}

class DrugSearchResult {
  final bool foundInLocal;
  final bool foundInOpenFda;
  final String? suggestedName;

  DrugSearchResult({
    required this.foundInLocal,
    required this.foundInOpenFda,
    this.suggestedName,
  });
}

class ScoredSentence {
  final String sentence;
  final int score;

  ScoredSentence(this.sentence, this.score);
}

class EnhancedDrugData {
  final List<ParsedInteraction> localInteractions;
  final List<ParsedInteraction> openFdaInteractions;
  final List<String> generalWarnings;
  final bool hasData;
  final bool foundInLocal;
  final bool foundInOpenFda;
  final bool foundInAnyDatabase;

  EnhancedDrugData({
    required this.localInteractions,
    required this.openFdaInteractions,
    required this.generalWarnings,
    required this.hasData,
    required this.foundInLocal,
    required this.foundInOpenFda,
    required this.foundInAnyDatabase,
  });
}

enum InteractionSeverity { major, moderate, minor, unknown }

class ParsedInteraction {
  final String interactsWith;
  final String description;
  final InteractionSeverity severity;
  final String source;

  ParsedInteraction({
    required this.interactsWith,
    required this.description,
    required this.severity,
    required this.source,
  });
}

class CrossDrugInteraction {
  final String drug1;
  final String drug2;
  final String description;
  final InteractionSeverity severity;
  final String source;

  CrossDrugInteraction({
    required this.drug1,
    required this.drug2,
    required this.description,
    required this.severity,
    this.source = '',
  });
}

class DrugInteractionResult {
  final String drugName;
  final List<ParsedInteraction> localInteractions;
  final List<ParsedInteraction> openFdaInteractions;
  final List<CrossDrugInteraction> crossInteractions;
  final List<String> generalWarnings;
  final bool hasData;

  DrugInteractionResult({
    required this.drugName,
    required this.localInteractions,
    required this.openFdaInteractions,
    required this.crossInteractions,
    required this.generalWarnings,
    required this.hasData,
  });
}
