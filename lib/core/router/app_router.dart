import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/dashboard/presentation/hardware_dashboard_screen.dart';
import '../../features/alerts/presentation/alerts_list_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/maintenance/presentation/maintenance_screen.dart';
import '../../features/admin/presentation/pending_requests_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // 🔄 Watch the login state stream to see who is logged in
  final authState = ref.watch(authControllerProvider);
  
  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const HardwareDashboardScreen(),
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
      // 👑 Add an explicit path routing parameter for your Admin layout
      GoRoute(
        path: '/admin',
        builder: (context, state) => const PendingRequestsScreen(),
      ),
    ],
    // 🔄 🛠️ REDIRECT CONTROLLER ENGINE
    redirect: (context, state) {
      final user = authState.valueOrNull;
      final isAtLogin = state.matchedLocation == '/login';

      // 1. If not logged in, keep them locked on the login screen
      if (user == null) {
        return isAtLogin ? null : '/login';
      }

      // 2. If logged in and hitting the login page or /dashboard, separate views by role
      if (isAtLogin || state.matchedLocation == '/dashboard') {
        final currentRole = user.role.toUpperCase();

        if (currentRole == 'ADMIN') {
          return '/admin'; // 🚀 Jump straight to PendingRequestsScreen if they are ADMIN!
        }
      }

      return null;
    },
  );
});
