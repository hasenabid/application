import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../zones/presentation/zones_controller.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _applyToAll = false;
  double _globalSetpoint = 150.0;
  final Map<String, double> _localSetpoints = {};

  @override
  Widget build(BuildContext context) {
    final zonesState = ref.watch(zonesControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Réglages'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: zonesState.when(
        data: (zones) {
          // Initialize local setpoints if empty
          if (_localSetpoints.isEmpty && zones.isNotEmpty) {
            for (var z in zones) {
              _localSetpoints[z.id] = z.setpointTemperature;
            }
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  title: const Text('Mode ONE / ALL', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Appliquer à toutes les zones'),
                  value: _applyToAll,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) {
                    setState(() {
                      _applyToAll = val;
                    });
                  },
                ),
                const Divider(),
                if (_applyToAll) ...[
                  const Text('Température Cible Globale', style: TextStyle(fontWeight: FontWeight.bold)),
                  Slider(
                    value: _globalSetpoint,
                    min: 0,
                    max: 300,
                    divisions: 300,
                    label: '${_globalSetpoint.round()}°C',
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() {
                        _globalSetpoint = val;
                      });
                    },
                  ),
                  Text('Valeur: ${_globalSetpoint.round()}°C', style: const TextStyle(fontSize: 16)),
                ] else ...[
                  Expanded(
                    child: ListView.builder(
                      itemCount: zones.length,
                      itemBuilder: (context, index) {
                        final zone = zones[index];
                        final val = _localSetpoints[zone.id] ?? 0.0;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${zone.name} - Cible', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Slider(
                              value: val,
                              min: 0,
                              max: 300,
                              divisions: 300,
                              label: '${val.round()}°C',
                              activeColor: AppColors.primary,
                              onChanged: (newVal) {
                                setState(() {
                                  _localSetpoints[zone.id] = newVal;
                                });
                              },
                            ),
                            Text('Valeur: ${val.round()}°C'),
                            const SizedBox(height: 16),
                          ],
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      final notifier = ref.read(zonesControllerProvider.notifier);
                      
                      Map<String, double> newSetpoints = {};
                      if (_applyToAll) {
                        for (var zone in zones) {
                          newSetpoints[zone.id] = _globalSetpoint;
                        }
                      } else {
                        newSetpoints = Map.from(_localSetpoints);
                      }
                      
                      notifier.updateSetpoints(newSetpoints);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Changements enregistrés. Les voyants ont été mis à jour.')),
                      );
                      context.go('/dashboard');
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    child: const Text('Enregistrer', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erreur: $err')),
      ),
    );
  }
}
