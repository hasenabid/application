import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

import '../../../../core/services/gemini_service.dart';
import '../../../zones/presentation/zones_controller.dart';
import '../../../zones/domain/models/thermoplay_zone.dart';

class VoiceAssistantButton extends ConsumerWidget {
  const VoiceAssistantButton({super.key});

  void _showVoiceDialog(BuildContext context, WidgetRef ref) {
    HapticFeedback.heavyImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _VoiceAssistantBottomSheet(ref: ref),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Positioned(
      bottom: 100,
      right: 24,
      child: GestureDetector(
        onTap: () => _showVoiceDialog(context, ref),
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.cyanAccent.withValues(alpha: 0.2),
            border: Border.all(
                color: Colors.cyanAccent.withValues(alpha: 0.5), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.cyanAccent.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.mic, color: Colors.cyanAccent, size: 32),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

enum _Phase { idle, listening, thinking, responding, error }

class _VoiceAssistantBottomSheet extends StatefulWidget {
  final WidgetRef ref;
  const _VoiceAssistantBottomSheet({required this.ref});

  @override
  State<_VoiceAssistantBottomSheet> createState() =>
      _VoiceAssistantBottomSheetState();
}

class _VoiceAssistantBottomSheetState extends State<_VoiceAssistantBottomSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  late GeminiService _gemini;

  _Phase _phase = _Phase.idle;
  String _displayText = '';
  String _recognizedWords = '';
  final List<_Msg> _messages = [];
  bool _speechAvailable = false;
  bool _isProcessing = false;
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _gemini = widget.ref.read(geminiServiceProvider);
    _setup();
  }

  Future<void> _setup() async {
    try {
      await _tts.setLanguage('fr-FR');
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.0);
    } catch (_) {}

    try {
      _speechAvailable = await _speech.initialize(
        onError: (e) {
          debugPrint('STT error: ${e.errorMsg}');
        },
      );
    } catch (_) {
      _speechAvailable = false;
    }

    if (!mounted) return;

    if (_speechAvailable) {
      _startListening();
    } else {
      setState(() {
        _phase = _Phase.error;
        _displayText =
            'Microphone non disponible.\nVérifiez les permissions.';
      });
    }
  }

  void _startListening() {
    if (!_speechAvailable || _isProcessing) return;

    _recognizedWords = '';
    setState(() {
      _phase = _Phase.listening;
      _displayText = 'Parlez maintenant...';
    });
    _pulseCtrl.repeat(reverse: true);

    // 🛠️ FIXED: Removed 'options' wrapper to match your local package version specifications
    _speech.listen(
      onResult: (SpeechRecognitionResult result) {
        if (!mounted) return;
        setState(() {
          _recognizedWords = result.recognizedWords;
          if (_recognizedWords.isNotEmpty) {
            _displayText = '« $_recognizedWords »';
          }
        });

        if (result.finalResult && _recognizedWords.isNotEmpty) {
          _processCommand(_recognizedWords);
        }
      },
      localeId: 'fr_FR',
    );
  }

  void _processCommand(String command) async {
    if (_isProcessing || !mounted) return;
    _isProcessing = true;

    _speech.stop();

    setState(() {
      _phase = _Phase.thinking;
      _displayText = 'AURA analyse votre demande...';
      _messages.add(_Msg(text: command, isUser: true));
    });
    HapticFeedback.lightImpact();

    try {
      final zones = widget.ref.read(zonesControllerProvider).valueOrNull ?? [];
      
      // 🛠️ FIXED: Casting explicitly to support dynamic model arguments inside GeminiService processing methods
      final aiResponse = await _gemini.processCommand(command, zones.cast<ThermoplayZone>());

      if (!mounted) return;

      if (aiResponse.actions.isNotEmpty) {
        final updates = <String, double>{};
        for (var action in aiResponse.actions) {
          if (action.newSetpoint != null) {
            updates[action.zoneId] = action.newSetpoint!;
          }
        }
        if (updates.isNotEmpty) {
          widget.ref
              .read(zonesControllerProvider.notifier)
              .updateSetpoints(updates);
          HapticFeedback.heavyImpact();
        }
      }

      setState(() {
        _phase = _Phase.responding;
        _displayText = aiResponse.message;
        _messages.add(_Msg(text: aiResponse.message, isUser: false));
        _pulseCtrl.stop();
      });

      try {
        await _tts.speak(aiResponse.message);
      } catch (_) {}
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.error;
        _displayText = 'Erreur : $e';
        _pulseCtrl.stop();
      });
    } finally {
      _isProcessing = false;
    }
  }

  void _retry() {
    _speech.stop();
    _tts.stop();
    _isProcessing = false;
    _startListening();
  }

  void _submitText() {
    final text = _textController.text.trim();
    if (text.isEmpty || _isProcessing) return;
    _textController.clear();
    _processCommand(text);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _speech.stop();
    _speech.cancel();
    _tts.stop();
    _textController.dispose();
    super.dispose();
  }

  Color get _color {
    switch (_phase) {
      case _Phase.idle:
        return Colors.white54;
      case _Phase.listening:
        return Colors.redAccent;
      case _Phase.thinking:
        return Colors.amberAccent;
      case _Phase.responding:
        return Colors.cyanAccent;
      case _Phase.error:
        return Colors.orangeAccent;
    }
  }

  IconData get _icon {
    switch (_phase) {
      case _Phase.idle:
        return Icons.mic_none;
      case _Phase.listening:
        return Icons.mic;
      case _Phase.thinking:
        return Icons.auto_awesome;
      case _Phase.responding:
        return Icons.smart_toy;
      case _Phase.error:
        return Icons.warning_amber_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.55,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: BoxDecoration(
            color: const Color(0xFF0D0D12).withValues(alpha: 0.92),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                  color: _color.withValues(alpha: 0.5), width: 2),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                // 🛠️ FIXED: Changed to valid EdgeInsets layout configuration signature constructor
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_icon, color: _color, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      _displayText,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.rajdhani(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Added retry button callback actions placeholder structure 
                    if (_phase == _Phase.error)
                      ElevatedButton.icon(
                        onPressed: _retry,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Réessayer'),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Msg {
  final String text;
  final bool isUser;
  _Msg({required this.text, required this.isUser});
}
