import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../dashboard/presentation/widgets/animated_background.dart';
import '../../zones/data/temp_request_repository.dart';

class PendingRequestsScreen extends ConsumerWidget {
  const PendingRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(pendingRequestsProvider);

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('DEMANDES EN ATTENTE',
            style: GoogleFonts.orbitron(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.5)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.cyanAccent),
            onPressed: () => ref.invalidate(pendingRequestsProvider),
          ),
        ],
      ),
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: requestsAsync.when(
              data: (requests) => requests.isEmpty
                  ? _buildEmpty()
                  : _buildList(context, ref, requests),
              loading: () => const Center(
                  child: CircularProgressIndicator(color: Colors.cyanAccent)),
              error: (e, _) => Center(
                  child: Text('Erreur : $e',
                      style: const TextStyle(color: Colors.redAccent))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline,
              color: Colors.greenAccent.withValues(alpha: 0.5), size: 64),
          const SizedBox(height: 16),
          Text('Aucune demande en attente',
              style: GoogleFonts.orbitron(
                  color: Colors.white38, fontSize: 14, letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildList(
      BuildContext context, WidgetRef ref, List<TempRequest> requests) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: requests.length,
      itemBuilder: (_, i) => _RequestCard(
        request: requests[i],
        onApprove: () async {
          await ref
              .read(tempRequestRepositoryProvider)
              .approve(requests[i].id);
          ref.invalidate(pendingRequestsProvider);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Demande approuvée',
                  style: GoogleFonts.rajdhani(
                      color: Colors.black, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.greenAccent,
              behavior: SnackBarBehavior.floating,
            ));
          }
        },
        onReject: () async {
          await ref
              .read(tempRequestRepositoryProvider)
              .reject(requests[i].id);
          ref.invalidate(pendingRequestsProvider);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Demande refusée',
                  style: GoogleFonts.rajdhani(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ));
          }
        },
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final TempRequest request;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _RequestCard({
    required this.request,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: Colors.orangeAccent.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.orangeAccent.withValues(alpha: 0.4)),
                      ),
                      child: Text(request.zoneName,
                          style: GoogleFonts.orbitron(
                              color: Colors.orangeAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ),
                    const Spacer(),
                    const Icon(Icons.access_time,
                        color: Colors.white38, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      request.createdAt.length > 16
                          ? request.createdAt.substring(0, 16)
                          : request.createdAt,
                      style: GoogleFonts.rajdhani(
                          color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Détails
                Row(
                  children: [
                    const Icon(Icons.engineering,
                        color: Colors.white54, size: 16),
                    const SizedBox(width: 6),
                    Text(request.workerName,
                        style: GoogleFonts.rajdhani(
                            color: Colors.white70, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 10),

                // Températures
                Row(
                  children: [
                    _TempChip(
                        label: 'Actuelle',
                        value: '${request.currentMaxTemp.toStringAsFixed(0)}°C',
                        color: Colors.white38),
                    const SizedBox(width: 12),
                    const Icon(Icons.arrow_forward,
                        color: Colors.white38, size: 16),
                    const SizedBox(width: 12),
                    _TempChip(
                        label: 'Demandée',
                        value:
                            '${request.requestedMaxTemp.toStringAsFixed(0)}°C',
                        color: Colors.cyanAccent),
                  ],
                ),
                const SizedBox(height: 16),

                // Boutons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onReject,
                        icon: const Icon(Icons.close,
                            size: 16, color: Colors.redAccent),
                        label: Text('REFUSER',
                            style: GoogleFonts.orbitron(
                                fontSize: 11,
                                color: Colors.redAccent,
                                letterSpacing: 1)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: Colors.redAccent.withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onApprove,
                        icon: const Icon(Icons.check, size: 16),
                        label: Text('APPROUVER',
                            style: GoogleFonts.orbitron(
                                fontSize: 11, letterSpacing: 1)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.greenAccent,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TempChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _TempChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.rajdhani(
                color: Colors.white38, fontSize: 10, letterSpacing: 1)),
        Text(value,
            style: GoogleFonts.orbitron(
                color: color, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
