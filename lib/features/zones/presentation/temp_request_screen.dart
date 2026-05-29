import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../auth/presentation/auth_controller.dart';
import '../../dashboard/presentation/widgets/animated_background.dart';
import '../data/temp_request_repository.dart';
import 'zones_controller.dart';

class TempRequestScreen extends ConsumerStatefulWidget {
  const TempRequestScreen({super.key});

  @override
  ConsumerState<TempRequestScreen> createState() => _TempRequestScreenState();
}

class _TempRequestScreenState extends ConsumerState<TempRequestScreen> {
  String? _selectedZoneId;
  String _selectedZoneName = '';
  double _currentMax = 150;
  final _newTempController = TextEditingController();
  bool _isSubmitting = false;
  String? _successMessage;
  String? _errorMessage;

  @override
  void dispose() {
    _newTempController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedZoneId == null) {
      setState(() => _errorMessage = 'Sélectionnez une zone');
      return;
    }
    final raw = double.tryParse(_newTempController.text.trim());
    if (raw == null || raw <= 0) {
      setState(() => _errorMessage = 'Température invalide');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final user = ref.read(authControllerProvider).valueOrNull;
      await ref.read(tempRequestRepositoryProvider).submitRequest(
            zoneId: _selectedZoneId!,
            zoneName: _selectedZoneName,
            workerName: user?.name ?? 'Ouvrier',
            currentMaxTemp: _currentMax,
            requestedMaxTemp: raw,
          );
      setState(() {
        _successMessage =
            'Demande envoyée à l\'administrateur pour validation';
        _newTempController.clear();
        _selectedZoneId = null;
      });
    } catch (e) {
      setState(() => _errorMessage = 'Erreur lors de l\'envoi : $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final zonesAsync = ref.watch(zonesControllerProvider);

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
        title: Text('DEMANDE TEMPÉRATURE',
            style: GoogleFonts.orbitron(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.5)),
      ),
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoBanner(),
                  const SizedBox(height: 16),
                  _buildZonePicker(zonesAsync),
                  const SizedBox(height: 16),
                  _buildTempInput(),
                  const SizedBox(height: 24),
                  if (_successMessage != null) _buildSuccess(),
                  if (_errorMessage != null) _buildError(),
                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.orangeAccent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: Colors.orangeAccent.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline,
                  color: Colors.orangeAccent, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'La nouvelle température maximale doit être validée par l\'administrateur avant d\'être appliquée.',
                  style: GoogleFonts.rajdhani(
                      color: Colors.white70, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildZonePicker(AsyncValue zonesAsync) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ZONE CONCERNÉE',
              style: GoogleFonts.orbitron(
                  color: Colors.white38,
                  fontSize: 11,
                  letterSpacing: 1.5)),
          const SizedBox(height: 12),
          zonesAsync.when(
            data: (zones) => DropdownButtonFormField<String>(
              dropdownColor: const Color(0xFF1A1A2E),
              style: GoogleFonts.rajdhani(
                  color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.black.withValues(alpha: 0.3),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: Colors.white.withValues(alpha: 0.1))),
              ),
              hint: Text('Sélectionner une zone',
                  style: GoogleFonts.rajdhani(
                      color: Colors.white38, fontSize: 15)),
              initialValue: _selectedZoneId,
              items: zones.map((z) {
                return DropdownMenuItem<String>(
                  value: z.id,
                  child: Text(z.name),
                );
              }).toList(),
              onChanged: (val) {
                if (val == null) return;
                final zone = zones.firstWhere((z) => z.id == val);
                setState(() {
                  _selectedZoneId = val;
                  _selectedZoneName = zone.name;
                  _currentMax = zone.setpointTemperature;
                });
              },
            ),
            loading: () => const CircularProgressIndicator(
                color: Colors.cyanAccent),
            error: (_, __) => Text('Zones non disponibles',
                style: GoogleFonts.rajdhani(
                    color: Colors.redAccent)),
          ),
          if (_selectedZoneId != null) ...[
            const SizedBox(height: 10),
            Text(
              'Consigne actuelle : ${_currentMax.toStringAsFixed(0)} °C',
              style: GoogleFonts.rajdhani(
                  color: Colors.white54, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTempInput() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('NOUVELLE TEMPÉRATURE MAXIMALE',
              style: GoogleFonts.orbitron(
                  color: Colors.white38, fontSize: 11, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          TextField(
            controller: _newTempController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.orbitron(
                color: Colors.cyanAccent, fontSize: 20),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.3),
              hintText: 'ex: 165',
              hintStyle: GoogleFonts.orbitron(
                  color: Colors.white24, fontSize: 20),
              suffixText: '°C',
              suffixStyle: GoogleFonts.orbitron(
                  color: Colors.white38, fontSize: 14),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      BorderSide(color: Colors.cyanAccent.withValues(alpha: 0.3))),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.cyanAccent)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      BorderSide(color: Colors.white.withValues(alpha: 0.1))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.greenAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
          const SizedBox(width: 10),
          Expanded(
              child: Text(_successMessage!,
                  style: GoogleFonts.rajdhani(
                      color: Colors.greenAccent, fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
          const SizedBox(width: 10),
          Expanded(
              child: Text(_errorMessage!,
                  style: GoogleFonts.rajdhani(
                      color: Colors.redAccent, fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.cyanAccent,
          foregroundColor: Colors.black,
          disabledBackgroundColor: Colors.cyanAccent.withValues(alpha: 0.3),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.black, strokeWidth: 2.5))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.send, size: 18),
                  const SizedBox(width: 10),
                  Text('ENVOYER LA DEMANDE',
                      style: GoogleFonts.orbitron(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1)),
                ],
              ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: child,
        ),
      ),
    );
  }
}
