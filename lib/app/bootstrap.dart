import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../core/di/injection.dart';
import '../features/auth/presentation/cubit/auth_cubit.dart';
import '../features/requests/presentation/cubit/sync_cubit.dart';
import 'app.dart';

/// Composition root: initialize platform services, build the DI graph and the
/// initial app state, then hand back the widget to run.
Future<Widget> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);

  final (databaseFactory, databasePath) = await _resolveDatabase();
  final prefs = await SharedPreferences.getInstance();

  await configureDependencies(
    prefs: prefs,
    databaseFactory: databaseFactory,
    databasePath: databasePath,
  );

  // Restore session (decides the initial route) and start the sync coordinator.
  await sl<AuthCubit>().checkAuth();
  await sl<SyncCubit>().init();

  return const App();
}

/// Picks the right sqflite backend per platform: the native plugin on
/// Android/iOS, the FFI backend on desktop.
Future<(sqflite.DatabaseFactory, String)> _resolveDatabase() async {
  if (Platform.isAndroid || Platform.isIOS) {
    final dir = await sqflite.getDatabasesPath();
    return (sqflite.databaseFactory, p.join(dir, 'solicita.db'));
  }
  sqfliteFfiInit();
  final dir = await databaseFactoryFfi.getDatabasesPath();
  return (databaseFactoryFfi, p.join(dir, 'solicita.db'));
}
