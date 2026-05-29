import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  final List<Map<String, dynamic>> _maintenances = [
    {'id': 1, 'title': 'Vérification Capteurs Zone 1', 'status': 'En cours', 'date': '2026-04-23'},
    {'id': 2, 'title': 'Remplacement Fusible Z3', 'status': 'Terminée', 'date': '2026-04-20'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maintenance'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Simuler l'ajout
              setState(() {
                _maintenances.insert(0, {
                  'id': DateTime.now().millisecondsSinceEpoch,
                  'title': 'Nouvelle tâche de maintenance',
                  'status': 'À faire',
                  'date': DateTime.now().toString().substring(0, 10),
                });
              });
            },
          )
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _maintenances.length,
        itemBuilder: (context, index) {
          final item = _maintenances[index];
          final isDone = item['status'] == 'Terminée';
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: Icon(
                isDone ? Icons.check_circle : Icons.build,
                color: isDone ? AppColors.ledOk : AppColors.primary,
              ),
              title: Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${item['date']} - ${item['status']}'),
              trailing: isDone ? null : IconButton(
                icon: const Icon(Icons.done, color: AppColors.ledOk),
                onPressed: () {
                  setState(() {
                    item['status'] = 'Terminée';
                  });
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
