import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../../features/ai/data/local_ai_service.dart';
import '../../features/ai/data/remote_ai_service.dart';
import '../../features/ai/domain/ai_service.dart';
import '../../features/ai/domain/usecases/suggest_request_meta.dart';
import '../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/get_current_session.dart';
import '../../features/auth/domain/usecases/login.dart';
import '../../features/auth/domain/usecases/logout.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/requests/data/datasources/request_local_datasource.dart';
import '../../features/requests/data/datasources/request_remote_datasource.dart';
import '../../features/requests/data/repositories/request_repository_impl.dart';
import '../../features/requests/domain/repositories/request_repository.dart';
import '../../features/requests/domain/usecases/create_request.dart';
import '../../features/requests/domain/usecases/get_request_detail.dart';
import '../../features/requests/domain/usecases/get_requests.dart';
import '../../features/requests/domain/usecases/sync_pending_actions.dart';
import '../../features/requests/domain/usecases/update_request_status.dart';
import '../../features/requests/presentation/cubit/create_request_cubit.dart';
import '../../features/requests/presentation/cubit/request_detail_cubit.dart';
import '../../features/requests/presentation/cubit/requests_list_cubit.dart';
import '../../features/requests/presentation/cubit/sync_cubit.dart';
import '../config/app_config.dart';
import '../database/app_database.dart';
import '../network/dio_client.dart';
import '../network/network_info.dart';
import '../theme/brand_cubit.dart';

/// Service locator. get_it is intentionally lightweight (no codegen) so the
/// wiring is explicit and easy to follow.
final GetIt sl = GetIt.instance;

/// Registers the whole graph. The platform-specific bits (database factory,
/// path) are passed in from `bootstrap` so this stays testable and pure.
Future<void> configureDependencies({
  required SharedPreferences prefs,
  required DatabaseFactory databaseFactory,
  required String databasePath,
}) async {
  // --- External / platform ---------------------------------------------------
  sl
    ..registerSingleton<SharedPreferences>(prefs)
    ..registerLazySingleton<FlutterSecureStorage>(
      () => const FlutterSecureStorage(),
    )
    ..registerLazySingleton<Connectivity>(Connectivity.new)
    ..registerLazySingleton<AppDatabase>(
      () => AppDatabase(factory: databaseFactory, path: databasePath),
    )
    ..registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));

  // --- Auth ------------------------------------------------------------------
  sl
    ..registerLazySingleton<AuthLocalDataSource>(
      () => AuthLocalDataSourceImpl(sl()),
    )
    ..registerLazySingleton<AuthRemoteDataSource>(
      () => const AuthRemoteDataSourceImpl(),
    )
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(remote: sl(), local: sl()),
    )
    ..registerLazySingleton(() => Login(sl()))
    ..registerLazySingleton(() => Logout(sl()))
    ..registerLazySingleton(() => GetCurrentSession(sl()))
    ..registerLazySingleton(
      () => AuthCubit(login: sl(), logout: sl(), getCurrentSession: sl()),
    );

  // --- Networking (depends on auth token) ------------------------------------
  sl.registerLazySingleton<Dio>(
    () => DioFactory.create(
      baseUrl: AppConfig.apiBaseUrl,
      tokenProvider: () async =>
          (await sl<AuthLocalDataSource>().readSession())?.token,
    ),
  );

  // --- AI --------------------------------------------------------------------
  sl
    ..registerLazySingleton<AiService>(
      // Real LLM when a key is configured, deterministic heuristic otherwise.
      () => AppConfig.hasAiKey
          ? RemoteAiService(dio: sl())
          : const LocalAiService(),
    )
    ..registerLazySingleton(() => SuggestRequestMeta(sl()));

  // --- Requests --------------------------------------------------------------
  sl
    ..registerLazySingleton<RequestRemoteDataSource>(
      () => RequestRemoteDataSourceImpl(sl()),
    )
    ..registerLazySingleton<RequestLocalDataSource>(
      () => RequestLocalDataSourceImpl(sl()),
    )
    // Singleton: it owns the pending-count stream and the offline queue state.
    ..registerLazySingleton<RequestRepository>(
      () => RequestRepositoryImpl(
        remote: sl(),
        local: sl(),
        networkInfo: sl(),
      ),
    )
    ..registerLazySingleton(() => GetRequests(sl()))
    ..registerLazySingleton(() => GetRequestDetail(sl()))
    ..registerLazySingleton(() => CreateRequest(sl()))
    ..registerLazySingleton(() => UpdateRequestStatus(sl()))
    ..registerLazySingleton(() => SyncPendingActions(sl()));

  // --- Cubits ----------------------------------------------------------------
  sl
    ..registerLazySingleton(() => BrandCubit(sl()))
    ..registerLazySingleton(
      () => SyncCubit(
        syncPendingActions: sl(),
        repository: sl(),
        networkInfo: sl(),
      ),
    )
    // Page-scoped cubits: a fresh instance per screen.
    ..registerFactory(() => RequestsListCubit(sl()))
    ..registerFactory(
      () => RequestDetailCubit(
        getRequestDetail: sl(),
        updateRequestStatus: sl(),
      ),
    )
    ..registerFactory(
      () => CreateRequestCubit(createRequest: sl(), suggestRequestMeta: sl()),
    );
}
