import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

import '../presentation/auth_controller.dart';
import '../domain/models/user.dart';
import '../../dashboard/presentation/widgets/animated_background.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  ConsumerState<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final _pinController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  String? _expectedOtp;
  
  // ===========================================================================
  // ⚠️ CONFIGURATION EMAIL À REMPLIR PAR L'UTILISATEUR ⚠️
  // ===========================================================================
  final String _emailAddress = 'azhardrira2@gmail.com';
  // Remplacer 'VOTRE_MOT_DE_PASSE_APP' par le mot de passe d'application Google (16 lettres sans espace)
  final String _emailAppPassword = 'VOTRE_MOT_DE_PASSE_APP'; 
  // ===========================================================================

  @override
  void initState() {
    super.initState();
    _sendOtpEmail();
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _sendOtpEmail() async {
    // Generate a random 4-digit code
    _expectedOtp = (1000 + Random().nextInt(9000)).toString();

    // If password is not configured, we fallback to '1234' for demo purposes
    if (_emailAppPassword == 'VOTRE_MOT_DE_PASSE_APP') {
      _expectedOtp = '1234';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSnackBar(
          'Email non configuré. Mode Démo actif : Utilisez le code 1234.',
          Colors.orangeAccent,
        );
      });
      return;
    }

    try {
      final smtpServer = gmail(_emailAddress, _emailAppPassword);
      final message = Message()
        ..from = Address(_emailAddress, 'AURA Système')
        ..recipients.add(_emailAddress)
        ..subject = 'Code de Sécurité AURA Admin'
        ..html = '''
          <div style="font-family: sans-serif; text-align: center; padding: 20px;">
            <h2>Système de Supervision AURA</h2>
            <p>Une tentative de connexion Administrateur a été détectée.</p>
            <p>Voici votre code de sécurité à usage unique :</p>
            <h1 style="color: #00bcd4; font-size: 40px; letter-spacing: 5px;">$_expectedOtp</h1>
            <p style="color: #888; font-size: 12px;">Ce code est valide pour cette session uniquement.</p>
          </div>
        ''';

      await send(message, smtpServer);

      if (mounted) {
        _showSnackBar(
          'Le code de sécurité a été envoyé à $_emailAddress',
          Colors.cyanAccent,
        );
      }
    } catch (e) {
      print('Erreur d\'envoi email: $e');
      // Fallback
      _expectedOtp = '1234';
      if (mounted) {
        _showSnackBar(
          'Erreur d\'envoi d\'email. Mode secours: code 1234.',
          Colors.redAccent,
        );
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.rajdhani(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: color.withValues(alpha: 0.9),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _verifyOtp() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    if (_pinController.text == _expectedOtp) {
      ref.read(authControllerProvider.notifier).loginWithRfid(
        const User(
          id: 'otp-admin',
          email: 'admin@aura.com',
          name: 'Admin AURA',
          token: 'otp_token_admin',
          role: 'ADMIN',
        ),
      );
      if (mounted) {
        context.go('/dashboard');
      }
    } else {
      setState(() {
        _isLoading = false;
        _error = 'Code incorrect. Veuillez réessayer.';
        _pinController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.cyanAccent.withValues(alpha: 0.05),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.security,
                            size: 48,
                            color: Colors.cyanAccent,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'SÉCURITÉ ADMIN',
                            style: GoogleFonts.orbitron(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Entrez le code envoyé à votre adresse email.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.rajdhani(
                              fontSize: 14,
                              color: Colors.white54,
                            ),
                          ),
                          const SizedBox(height: 32),
                          TextField(
                            controller: _pinController,
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            obscureText: true,
                            obscuringCharacter: '●',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.orbitron(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.cyanAccent,
                              letterSpacing: 16,
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: Colors.black.withValues(alpha: 0.3),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: (val) {
                              if (val.length == 4) {
                                _verifyOtp();
                              }
                            },
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              _error!,
                              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                            ),
                          ],
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading || _pinController.text.length < 4
                                  ? null
                                  : _verifyOtp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.cyanAccent.withValues(alpha: 0.8),
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.black,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      'VÉRIFIER',
                                      style: GoogleFonts.rajdhani(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 2,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
