import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/constants.dart';
import '../features/auth/bloc/auth_bloc.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/audit/screens/audit_log_screen.dart';
import '../features/cases/screens/case_detail_screen.dart';
import '../features/cases/screens/cases_list_screen.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/emergency/screens/emergency_screen.dart';
import '../features/intel/screens/intel_list_screen.dart';
import '../features/intel/screens/report_form_screen.dart';
import '../features/map/screens/map_screen.dart';
import '../features/wearable_sync/screens/wearable_sync_screen.dart';

class AppRouter {
  AppRouter._();

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppConstants.routeLogin,
    redirect: (BuildContext context, GoRouterState state) {
      final authState = context.read<AuthBloc>().state;
      final isAuthenticated = authState is AuthAuthenticated;
      final isLoginRoute = state.matchedLocation == AppConstants.routeLogin;

      if (!isAuthenticated && !isLoginRoute) {
        return AppConstants.routeLogin;
      }
      if (isAuthenticated && isLoginRoute) {
        return AppConstants.routeDashboard;
      }
      return null;
    },
    refreshListenable: _AuthStateNotifier(),
    routes: [
      GoRoute(
        path: AppConstants.routeLogin,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppConstants.routeDashboard,
        builder: (_, __) => const DashboardScreen(),
      ),
      GoRoute(
        path: AppConstants.routeCases,
        builder: (_, __) => const CasesListScreen(),
      ),
      GoRoute(
        path: '/cases/:id',
        builder: (_, state) => CaseDetailScreen(
          caseId: state.pathParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: AppConstants.routeIntel,
        builder: (_, __) => const IntelListScreen(),
      ),
      GoRoute(
        path: AppConstants.routeIntelReport,
        builder: (_, __) => const ReportFormScreen(),
      ),
      GoRoute(
        path: AppConstants.routeMap,
        builder: (_, __) => const MapScreen(),
      ),
      GoRoute(
        path: AppConstants.routeEmergency,
        builder: (_, __) => const EmergencyScreen(),
      ),
      GoRoute(
        path: AppConstants.routeWearableSync,
        builder: (_, __) => const WearableSyncScreen(),
      ),
      GoRoute(
        path: AppConstants.routeAuditLog,
        builder: (_, __) => const AuditLogScreen(),
      ),
    ],
  );
}

/// Bridges AuthBloc state changes into GoRouter's Listenable refresh mechanism.
class _AuthStateNotifier extends ChangeNotifier {
  _AuthStateNotifier();
}
