import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/zones/domain/models/thermoplay_zone.dart';

// ============================================================================
// ⚠️ REMPLACER PAR VOTRE CLÉ API GEMINI (https://aistudio.google.com/apikey)
// ============================================================================
const String _geminiApiKey = 'AIzaSyDH48av168jxehCucuCttSeIpIlQ5ABgGc';

final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService();
});

/// Représente la réponse structurée de l'IA
class AiResponse {
  final String message;
  final List<AiAction> actions;

  const AiResponse({required this.message, this.actions = const []});
}

/// Action à exécuter sur une zone
class AiAction {
  final String zoneId;
  final double? newSetpoint;
  final String? newMode; // "auto", "manual", "standby"

  const AiAction({required this.zoneId, this.newSetpoint, this.newMode});
}

class GeminiService {
  GenerativeModel? _model;

  bool get isConfigured =>
      _geminiApiKey.isNotEmpty && _geminiApiKey != 'VOTRE_CLE_API_GEMINI';

  void _initModel() {
    if (_model != null) return;
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _geminiApiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 512,
      ),
    );
  }

  String _buildSystemContext(List<ThermoplayZone> zones) {
    final zonesInfo = zones.map((z) {
      return '- ${z.name} (id: ${z.id}): '
          'T° actuelle=${z.currentTemperature.toInt()}°C, '
          'Consigne=${z.setpointTemperature.toInt()}°C, '
          'Statut=${z.status.name}, '
          'Mode=${z.mode.name}, '
          'Puissance=${z.powerPercent}%';
    }).join('\n');

    return '''
Tu es AURA, l'assistant IA intelligent du système de supervision industrielle Thermoplay.
Tu contrôles un régulateur de température à canaux chauds pour l'injection plastique.

ÉTAT ACTUEL DES ZONES :
$zonesInfo

RÈGLES IMPORTANTES :
1. Tu réponds TOUJOURS en français, de manière concise et professionnelle.
2. Tu peux modifier les consignes de température des zones.
3. Les températures valides sont entre 0°C et 400°C.
4. Si l'utilisateur demande une information, réponds directement.
5. Si l'utilisateur demande une action, exécute-la ET confirme.

FORMAT DE RÉPONSE OBLIGATOIRE (JSON) :
{
  "message": "Ta réponse en langage naturel à l'utilisateur",
  "actions": [
    {"zoneId": "1", "newSetpoint": 160}
  ]
}

Si aucune action n'est requise, retourne "actions": [].
Retourne UNIQUEMENT le JSON, sans texte avant ou après.
''';
  }

  /// Traite une commande vocale avec le contexte des zones
  Future<AiResponse> processCommand(String userCommand, List<ThermoplayZone> zones) async {
    // Mode démo si la clé n'est pas configurée
    if (!isConfigured) {
      return _processDemoMode(userCommand, zones);
    }

    _initModel();

    try {
      final systemContext = _buildSystemContext(zones);

      final response = await _model!.generateContent([
        Content.text(systemContext),
        Content.text('Commande utilisateur : "$userCommand"'),
      ]);

      final responseText = response.text?.trim() ?? '';

      // Parse le JSON de la réponse
      return _parseAiResponse(responseText);
    } catch (e) {
      return AiResponse(
        message: 'Erreur de communication avec l\'IA : $e',
      );
    }
  }

  AiResponse _parseAiResponse(String responseText) {
    try {
      // Nettoyer le JSON (enlever les backticks markdown si présents)
      String cleaned = responseText;
      if (cleaned.contains('```json')) {
        cleaned = cleaned.split('```json').last.split('```').first.trim();
      } else if (cleaned.contains('```')) {
        cleaned = cleaned.split('```')[1].trim();
      }

      final json = jsonDecode(cleaned) as Map<String, dynamic>;
      final message = json['message'] as String? ?? 'Commande traitée.';
      final actionsList = json['actions'] as List<dynamic>? ?? [];

      final actions = actionsList.map((a) {
        final map = a as Map<String, dynamic>;
        return AiAction(
          zoneId: map['zoneId']?.toString() ?? '',
          newSetpoint: (map['newSetpoint'] as num?)?.toDouble(),
          newMode: map['newMode'] as String?,
        );
      }).toList();

      return AiResponse(message: message, actions: actions);
    } catch (e) {
      // Si le parsing JSON échoue, retourner le texte brut
      return AiResponse(message: responseText);
    }
  }

  /// Mode démo sans clé API — intelligence locale basique
  AiResponse _processDemoMode(String command, List<ThermoplayZone> zones) {
    final lower = command.toLowerCase();

    // Question sur l'état
    if (lower.contains('état') || lower.contains('statut') || lower.contains('comment') || lower.contains('température')) {
      final statusLines = zones.map((z) =>
        '${z.name}: ${z.currentTemperature.toInt()}°C (consigne: ${z.setpointTemperature.toInt()}°C) — ${z.status.name}'
      ).join('\n');
      return AiResponse(
        message: 'Voici l\'état actuel du système :\n$statusLines',
      );
    }

    // Commande d'augmentation
    bool isIncrease = lower.contains('augmente') || lower.contains('monte') || lower.contains('plus');
    bool isDecrease = lower.contains('diminue') || lower.contains('baisse') || lower.contains('moins') || lower.contains('réduit');

    if (isIncrease || isDecrease) {
      // Extraire le montant
      double amount = 5.0;
      final numMatch = RegExp(r'(\d+)').firstMatch(lower);
      if (numMatch != null) {
        final parsed = double.tryParse(numMatch.group(1)!);
        if (parsed != null && parsed > 0 && parsed <= 100) amount = parsed;
      }

      // Trouver la zone ciblée
      String? targetZoneId;
      String targetName = 'toutes les zones';
      for (var z in zones) {
        if (lower.contains(z.name.toLowerCase()) || lower.contains('zone ${z.id}')) {
          targetZoneId = z.id;
          targetName = z.name;
          break;
        }
      }

      final actions = <AiAction>[];
      if (targetZoneId != null) {
        final zone = zones.firstWhere((z) => z.id == targetZoneId);
        final newTemp = isIncrease
            ? zone.setpointTemperature + amount
            : zone.setpointTemperature - amount;
        actions.add(AiAction(zoneId: targetZoneId, newSetpoint: newTemp));
      } else {
        for (var z in zones) {
          final newTemp = isIncrease
              ? z.setpointTemperature + amount
              : z.setpointTemperature - amount;
          actions.add(AiAction(zoneId: z.id, newSetpoint: newTemp));
        }
      }

      final direction = isIncrease ? 'augmenté' : 'diminué';
      return AiResponse(
        message: 'Consigne $direction de ${amount.toInt()}°C pour $targetName.',
        actions: actions,
      );
    }

    return AiResponse(
      message: 'Mode démo actif. Pour activer l\'IA complète, '
          'configurez votre clé API Gemini dans gemini_service.dart.\n\n'
          'Essayez : "quel est l\'état des zones ?" ou "augmente la zone 1 de 10 degrés".',
    );
  }
}
