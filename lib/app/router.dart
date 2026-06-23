import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/di/injection.dart';
import '../features/auth/presentation/cubit/auth_cubit.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/requests/presentation/cubit/create_request_cubit.dart';
import '../features/requests/presentation/cubit/request_detail_cubit.dart';
import '../features/requests/presentation/cubit/requests_list_cubit.dart';
import '../features/requests/presentation/pages/create_request_page.dart';
import '../features/requests/presentation/pages/request_detail_page.dart';
import '../features/requests/presentation/pages/requests_list_page.dart';
import 'go_router_refresh_stream.dart';

/// Builds the app router. Route protection lives in [redirect], driven by the
/// [AuthCubit] passed in (also used as `refreshListenable`).
GoRouter buildRouter(AuthCubit authCubit) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(authCubit.stream),
    redirect: (context, state) {
      final status = authCubit.state.status;
      final loc = state.matchedLocation;

      // Still restoring the session from secure storage → show splash.
      if (status == AuthStatus.unknown) {
        return loc == '/' ? null : '/';
      }

      final loggedIn = status == AuthStatus.authenticated;
      final atLogin = loc == '/login';
      final atSplash = loc == '/';

      if (!loggedIn) return atLogin ? null : '/login';
      if (atLogin || atSplash) return '/requests';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const _SplashPage()),
      GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
      GoRoute(
        path: '/requests',
        builder: (_, _) => BlocProvider(
          create: (_) => sl<RequestsListCubit>()..load(),
          child: const RequestsListPage(),
        ),
      ),
      GoRoute(
        // Declared before ':id' so the literal segment wins.
        path: '/requests/new',
        builder: (_, _) => BlocProvider(
          create: (_) => sl<CreateRequestCubit>(),
          child: const CreateRequestPage(),
        ),
      ),
      GoRoute(
        path: '/requests/:id',
        builder: (_, state) => BlocProvider(
          create: (_) =>
              sl<RequestDetailCubit>()..load(state.pathParameters['id']!),
          child: const RequestDetailPage(),
        ),
      ),
    ],
  );
}

class _SplashPage extends StatelessWidget {
  const _SplashPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
