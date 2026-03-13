import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/dependency_injection.dart';
import '../../features/attendance/presentation/bloc/attendance_bloc.dart';
import '../../features/attendance/presentation/pages/attendance_stats_page.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import 'route_names.dart';

class AppRouter {
  AppRouter._();

  static final router = GoRouter(
    // Nếu đã đăng nhập → vào thẳng home; ngược lại → vào login
    initialLocation: FirebaseAuth.instance.currentUser != null
        ? RouteNames.home
        : RouteNames.login,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoggedIn = FirebaseAuth.instance.currentUser != null;
      final isOnLogin = state.matchedLocation == RouteNames.login;

      if (!isLoggedIn && !isOnLogin) return RouteNames.login;
      if (isLoggedIn && isOnLogin) return RouteNames.home;
      return null;
    },
    routes: [
      GoRoute(
        path: RouteNames.login,
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: RouteNames.home,
        name: 'home',
        builder: (context, state) => MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => sl<AuthBloc>()),
            BlocProvider(create: (_) => sl<AttendanceBloc>()),
          ],
          child: const HomePage(),
        ),
      ),
      GoRoute(
        path: RouteNames.attendanceStats,
        name: 'attendanceStats',
        builder: (context, state) => BlocProvider(
          create: (_) => sl<AttendanceBloc>(),
          child: const AttendanceStatsPage(),
        ),
      ),
    ],
  );
}
