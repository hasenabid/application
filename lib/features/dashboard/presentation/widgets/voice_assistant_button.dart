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
    // TTS
    try {
      await _tts.setLanguage('fr-FR');
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.0);
    } catch (_) {}

    // STT
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

    _speech.listen(
      onResult: (SpeechRecognitionResult result) {
        if (!mounted) return;
        setState(() {
          _recognizedWords = result.recognizedWords;
          if (_recognizedWords.isNotEmpty) {
            _displayText = '« $_recognizedWords »';
          }
        });

        // Quand la reconnaissance est finale, traiter la commande
        if (result.finalResult && _recognizedWords.isNotEmpty) {
          _processCommand(_recognizedWords);
        }
      },
      localeId: 'fr_FR',
      listenFor: const Duration(seconds: 15),
      pauseFor: const Duration(seconds: 3),
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
      final zones =
          widget.ref.read(zonesControllerProvider).valueOrNull ?? [];
      final aiResponse = await _gemini.processCommand(command, zones);

      if (!mounted) return;

      // Exécuter les actions
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

      // Lire la réponse à haute voix
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

  // ── Couleur selon la phase ──
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
              // Handle
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _color,
                          boxShadow: [
                            BoxShadow(
                              color: _color.withValues(alpha: 0.5),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'ASSISTANT AURA',
                        style: GoogleFonts.orbitron(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: _color.withValues(alpha: 0.25)),
                    ),
                    child: Text(
                      _gemini.isConfigured ? 'GEMINI IA' : 'MODE DÉMO',
                      style: GoogleFonts.rajdhani(
                        color: _color,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Content
              Expanded(
                child: _messages.isEmpty
                    ? _buildOrbView()
                    : _buildChatView(),
              ),
              const SizedBox(height: 12),

              // Saisie texte (alternative à la voix)
              _buildTextInput(),
              const SizedBox(height: 8),

              // Bottom bar
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Centre : Orbe animé + texte ──
  Widget _buildOrbView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (context, child) {
              final v = _pulseCtrl.value;
              return Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _color.withValues(alpha: 0.08),
                  boxShadow: [
                    BoxShadow(
                      color: _color.withValues(
                          alpha: _phase == _Phase.thinking
                              ? 0.5
                              : v * 0.4),
                      blurRadius:
                          _phase == _Phase.thinking ? 40 : 25 * v,
                      spreadRadius:
                          _phase == _Phase.thinking ? 12 : 6 * v,
                    ),
                  ],
                ),
                child: Icon(_icon, color: _color, size: 42),
              );
            },
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              _displayText,
              textAlign: TextAlign.center,
              style: GoogleFonts.rajdhani(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 16,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Chat : Historique des messages ──
  Widget _buildChatView() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            reverse: true,
            physics: const BouncingScrollPhysics(),
            itemCount: _messages.length +
                (_phase == _Phase.thinking ? 1 : 0),
            itemBuilder: (context, index) {
              if (_phase == _Phase.thinking && index == 0) {
                return _buildThinkingIndicator();
              }
              final adj = _phase == _Phase.thinking ? index - 1 : index;
              final msg = _messages[_messages.length - 1 - adj];
              return _buildBubble(msg);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildThinkingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 60),
      child: AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (context, _) {
          return Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.amberAccent.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(
                  color: Colors.amberAccent.withValues(
                      alpha: 0.1 + _pulseCtrl.value * 0.15)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome,
                    size: 14,
                    color: Colors.amberAccent.withValues(
                        alpha: 0.5 + _pulseCtrl.value * 0.5)),
                const SizedBox(width: 8),
                Text(
                  'AURA réfléchit...',
                  style: GoogleFonts.rajdhani(
                    color: Colors.amberAccent.withValues(alpha: 0.7),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBubble(_Msg msg) {
    final isUser = msg.isUser;
    return Padding(
      padding: EdgeInsets.only(
        bottom: 8,
        left: isUser ? 50 : 0,
        right: isUser ? 0 : 50,
      ),
      child: Align(
        alignment:
            isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isUser
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.cyanAccent.withValues(alpha: 0.07),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isUser ? 16 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 16),
            ),
            border: Border.all(
              color: isUser
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.cyanAccent.withValues(alpha: 0.12),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isUser ? Icons.person : Icons.auto_awesome,
                    size: 11,
                    color: isUser
                        ? Colors.white30
                        : Colors.cyanAccent.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    isUser ? 'VOUS' : 'AURA IA',
                    style: GoogleFonts.rajdhani(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: isUser
                          ? Colors.white24
                          : Colors.cyanAccent
                              .withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                msg.text,
                style: GoogleFonts.rajdhani(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 14,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextInput() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: TextField(
              controller: _textController,
              enabled: !_isProcessing,
              style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Écrire une commande...',
                hintStyle: GoogleFonts.rajdhani(color: Colors.white24, fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              onSubmitted: (_) => _submitText(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _submitText,
          child: Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: Colors.cyanAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.send, color: Colors.cyanAccent, size: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    final canRetry =
        _phase == _Phase.responding || _phase == _Phase.error;

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: canRetry ? _retry : null,
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: (_phase == _Phase.listening
                        ? Colors.redAccent
                        : Colors.cyanAccent)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (_phase == _Phase.listening
                          ? Colors.redAccent
                          : Colors.cyanAccent)
                      .withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _phase == _Phase.listening
                        ? Icons.mic
                        : Icons.refresh,
                    color: _phase == _Phase.listening
                        ? Colors.redAccent
                        : Colors.cyanAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _phase == _Phase.listening
                        ? 'ÉCOUTE EN COURS...'
                        : _phase == _Phase.thinking
                            ? 'ANALYSE...'
                            : 'NOUVELLE COMMANDE',
                    style: GoogleFonts.rajdhani(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _phase == _Phase.listening
                          ? Colors.redAccent
                          : Colors.cyanAccent,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () {
            _tts.stop();
            Navigator.of(context).pop();
          },
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: const Icon(Icons.close,
                color: Colors.white38, size: 18),
          ),
        ),
      ],
    );
  }
}

class _Msg {
  final String text;
  final bool isUser;
  const _Msg({required this.text, required this.isUser});
}
