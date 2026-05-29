import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../auth/presentation/auth_controller.dart';
import '../../zones/presentation/zones_controller.dart';
// 🛠️ CHANGED: Import the correct ThermoplayZone model definition file
import '../../zones/domain/models/thermoplay_zone.dart'; 
import '../../zones/presentation/temp_request_screen.dart';
import 'widgets/animated_background.dart';
import 'widgets/modern_zone_card.dart';
import 'widgets/voice_assistant_button.dart';

class WorkerDashboardScreen extends ConsumerWidget {
  const WorkerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zonesState = ref.watch(zonesControllerProvider);
    final user = ref.watch(authControllerProvider).valueOrNull;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withValues(alpha: 0.2)),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TABLEAU DE BORD OUVRIER',
              style: GoogleFonts.orbitron(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            if (user != null)
              Text(
                'Opérateur : ${user.name}',
                style: GoogleFonts.rajdhani(
                  fontSize: 14,
                  color: Colors.white54,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        actions: [
          // Bouton demande de changement de température
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orangeAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.4)),
            ),
            child: IconButton(
              icon: const Icon(Icons.thermostat, color: Colors.orangeAccent, size: 20),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const TempRequestScreen()),
              ),
              tooltip: 'Demander changement temp.',
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 8, right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: IconButton(
              icon: const Icon(Icons.power_settings_new,
                  color: Colors.redAccent, size: 20),
              onPressed: () {
                ref.read(authControllerProvider.notifier).logout();
                context.go('/login');
              },
              tooltip: 'Déconnexion',
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: zonesState.when(
              data: (zones) => _buildZonesGrid(context, ref, zones),
              loading: () => const Center(
                child: CircularProgressIndicator(color: Colors.cyanAccent),
              ),
              error: (e, _) => Center(
                child: Text('Erreur: $e',
                    style: const TextStyle(color: Colors.redAccent)),
              ),
            ),
          ),
          const VoiceAssistantButton(),
        ],
      ),
      // Bouton flottant pour demande de température
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.orangeAccent,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.thermostat),
        label: Text('Demande temp.',
            style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold)),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const TempRequestScreen()),
        ),
      ),
    );
  }

  Widget _buildZonesGrid(
    BuildContext context,
    WidgetRef ref,
    List<ThermoplayZone> zones, // 🛠️ FIXED: Parameter changed from List<AuraZone> to match your state data type
  ) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: GridView.builder(
        physics: const BouncingScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isTablet ? 2 : 1,
          childAspectRatio: isTablet ? 1.2 : 1.3,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
        ),
        itemCount: zones.length,
        itemBuilder: (context, index) {
          return ModernZoneCard(zone: zones[index], ref: ref);
        },
      ),
    );
  }
}
