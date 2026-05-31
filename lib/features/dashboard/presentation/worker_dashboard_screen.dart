import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../auth/presentation/auth_controller.dart';
import '../../zones/presentation/zones_controller.dart';
import '../../zones/domain/models/thermoplay_zone.dart';
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
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.4),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TABLEAU DE BORD ADMINISTRATEUR',
              style: GoogleFonts.orbitron(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            // 👑 EN-TÊTE PERSONNALISÉ DEMANDÉ AVEC VOTRE NOM
            Text(
              'Superviseur : ${user?.name ?? "Hassen Abid"}',
              style: GoogleFonts.rajdhani(
                fontSize: 14,
                color: Colors.cyanAccent,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        actions: [
          // 📥 👑 LE BOUTON CYAN LIÉ DYNAMIQUEMENT
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.cyanAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.4)),
            ),
            child: IconButton(
              icon: const Icon(Icons.move_to_inbox, color: Colors.cyanAccent, size: 20),
              onPressed: () {
                context.push('/admin'); // 🚀 Ouvre la liste des demandes des ouvriers !
              },
              tooltip: 'Voir les demandes ouvriers',
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 8, right: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: IconButton(
              icon: const Icon(Icons.power_settings_new, color: Colors.redAccent, size: 20),
              onPressed: () {
                ref.read(authControllerProvider.notifier).logout();
                context.go('/login');
              },
              tooltip: 'Déconnexion',
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: Column(
              children: [
                // 🎛️ SECTION CONTRÔLE GLOBAL DE L'IMAGE CIBLE
                _buildGlobalControlHeader(),
                
                // GRILLE DE SUPERVISION DES ZONES SANS OVERFLOW
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: zonesState.when(
                      data: (zones) => _buildZonesGrid(context, ref, zones),
                      loading: () => const Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
                      error: (e, _) => Center(child: Text('Erreur: $e', style: const TextStyle(color: Colors.redAccent))),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const VoiceAssistantButton(),
        ],
      ),
      // 📑 BARRE DE NAVIGATION INFÉRIEURE COMPLÈTE
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildGlobalControlHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'CONTRÔLE GLOBAL',
            style: GoogleFonts.orbitron(color: Colors.white70, fontSize: 14, letterSpacing: 1),
          ),
          Row(
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.withValues(alpha: 0.2)),
                onPressed: () {},
                child: Text('-1°C TOUT', style: GoogleFonts.rajdhani(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan.withValues(alpha: 0.2)),
                onPressed: () {},
                child: Text('+1°C TOUT', style: GoogleFonts.rajdhani(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildZonesGrid(BuildContext context, WidgetRef ref, List<ThermoplayZone> zones) {
    final width = MediaQuery.of(context).size.width;
    int crossAxisCount = width > 900 ? 2 : 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: 1.45, // Calibré pour afficher l'intégralité des anneaux sans pixel overflow
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: zones.length,
        itemBuilder: (context, index) {
          return ModernZoneCard(zone: zones[index], ref: ref);
        },
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      color: const Color(0xFF121218),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.dashboard, 'Accueil', '/dashboard', true, context),
          _navItem(Icons.notifications_outlined, 'Alertes', '/alerts', false, context),
          _navItem(Icons.settings_outlined, 'Réglages', '/settings', false, context),
          _navItem(Icons.build_outlined, 'Maint.', '/maintenance', false, context),
          _navItem(Icons.history, 'Historique', '/dashboard', false, context),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, String route, bool isActive, BuildContext context) {
    Color color = isActive ? Colors.cyanAccent : Colors.white54;
    return InkWell(
      onTap: () {
        if (!isActive) context.push(route);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.rajdhani(color: color, fontSize: 12, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
