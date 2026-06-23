import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/config/brand.dart';
import '../core/di/injection.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/brand_cubit.dart';
import '../features/auth/presentation/cubit/auth_cubit.dart';
import '../features/requests/presentation/cubit/sync_cubit.dart';
import 'router.dart';

/// Root widget. Provides the three app-wide cubits and rebuilds the whole
/// theme whenever the active [Brand] changes (the whitelabel switch).
class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final AuthCubit _authCubit;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authCubit = sl<AuthCubit>();
    _router = buildRouter(_authCubit);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authCubit),
        BlocProvider.value(value: sl<BrandCubit>()),
        BlocProvider.value(value: sl<SyncCubit>()),
      ],
      child: BlocBuilder<BrandCubit, Brand>(
        builder: (context, brand) {
          return MaterialApp.router(
            title: brand.name,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(brand),
            darkTheme: AppTheme.dark(brand),
            routerConfig: _router,
          );
        },
      ),
    );
  }
}
