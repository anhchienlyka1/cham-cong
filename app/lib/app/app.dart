import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../config/routes/app_router.dart';
import '../config/themes/app_theme.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import 'dependency_injection.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>.value(
      value: sl<AuthBloc>()..add(const AuthCheckStatusRequested()),
      child: MaterialApp.router(
        title: 'Chấm Công',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
