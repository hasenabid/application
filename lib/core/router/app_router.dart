import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/alerts/presentation/alerts_list_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/maintenance/presentation/maintenance_screen.dart';
import '../../features/admin/presentation/pending_requests_screen.dart';
import '../../features/dashboard/presentation/hardware_dashboard_screen.dart';

// 🛠️ 1. IMPORT DU BON ÉCRAN DE SUPERVISION ADMINISTRATEUR SOMBRE
//import '../../features/dashboard/presentation/dashboard_screen.dart'; 
import '../../features/dashboard/presentation/worker_dashboard_screen.dart';


final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      // 🛠️ 2. MISE À JOUR DE LA ROUTE PRINCIPALE POUR APPELER L'ÉCRAN RECHERCHÉ
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const WorkerDashboardScreen(),//HardwareDashboardScreen(), 
      ),
      GoRoute(
        path: '/alerts',
        builder: (context, state) => const AlertsListScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/maintenance',
        builder: (context, state) => const MaintenanceScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const PendingRequestsScreen(),
      ),
    ],

    redirect: (context, state) {
      final user = authState.valueOrNull;
      final isAtLogin = state.matchedLocation == '/login';

      if (user == null) {
        return isAtLogin ? null : '/login';
      }

      if (isAtLogin || state.matchedLocation == '/dashboard') {
        final currentRole = user.role.toUpperCase();

        // 👑 3. REDIRECTION DE L'ADMIN VERS CE COCKPIT DE SUPERVISION CENTRALISÉ
        if (currentRole == 'ADMIN') {
          return '/dashboard'; 
        }
      }

      return null;
    },
  );
});
