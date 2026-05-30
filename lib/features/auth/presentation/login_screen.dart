import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../domain/models/user.dart';
import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController =
      TextEditingController(text: 'admin@thermoplay.com');
  final _passwordController = TextEditingController(text: 'password123');

  // 🛠️ ADDED: Trigger the background polling loop when the login screen opens
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authControllerProvider.notifier).startRfidPollingLoop();
    });
  }

  // 🛠️ ADDED: Always stop network polling operations if the widget is destroyed
  @override
  void dispose() {
    ref.read(authControllerProvider.notifier).stopRfidPolling();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    ref.read(authControllerProvider.notifier).login(
          _emailController.text,
          _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<User?>>(authControllerProvider, (previous, next) {
      next.whenData((user) {
        if (user != null) {
          // 🛠️ FIXED: Stop the background polling loop once authentication succeeds
          ref.read(authControllerProvider.notifier).stopRfidPolling();

          // 🛠️ FIXED: Redirect cleanly based on user role strings
          final currentRole = user.role.toUpperCase();
          if (currentRole == 'ADMIN') {
            context.go('/admin'); // 🚀 Jump to Admin approvals panel
          } else {
            context.go('/dashboard'); // Go to standard telemetry dashboard view
          }
        }
      });
      next.whenOrNull(
        error: (err, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Connexion échouée: $err'),
                backgroundColor: AppColors.error),
          );
        },
      );
    });

    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 380),
            decoration: BoxDecoration(
              color: AppColors.panelBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFCCCCCC), width: 1),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 12,
                    offset: Offset(0, 4)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header band
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: const BoxDecoration(
                    color: AppColors.lcdBackground,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(10)),
                    border: Border(
                        bottom: BorderSide(color: Color(0xFF7A9CC0), width: 1)),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.thermostat_auto,
                          size: 44, color: AppColors.primary),
                      const SizedBox(height: 8),
                      Text(
                        'THERMOPLAY',
                        style: GoogleFonts.shareTechMono(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          letterSpacing: 3,
                        ),
                      ),
                      Text(
                        'TH-M6 — Supervision',
                        style: GoogleFonts.shareTechMono(
                          fontSize: 11,
                          color: AppColors.lcdText.withValues(alpha: 0.7),
                          letterSpacing: 1,
                        ),
                      ),
                      // 🛠️ VISUAL ANCHOR INDICATOR: Friendly notice indicating badge listener is operating
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 8,
                            height: 8,
                            child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.green),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Lecteur RFID actif...",
                            style: GoogleFonts.shareTechMono(fontSize: 10, color: Colors.green),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Form
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Identifiant',
                          prefixIcon: Icon(Icons.person_outline, size: 18),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(
                            fontSize: 14, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Mot de passe',
                          prefixIcon: Icon(Icons.lock_outline, size: 18),
                        ),
                        obscureText: true,
                        style: const TextStyle(
                            fontSize: 14, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: authState.isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6)),
                        ),
                        child: authState.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                'CONNEXION',
                                style: GoogleFonts.shareTechMono(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 2,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
