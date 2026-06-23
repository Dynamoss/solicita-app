import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../config/brand.dart';

/// Holds the active whitelabel [Brand] and persists the choice. Emitting a new
/// brand rebuilds the whole [MaterialApp] theme — that's the entire mechanism
/// behind the live brand switch.
class BrandCubit extends Cubit<Brand> {
  BrandCubit(this._prefs)
      : super(Brands.byId(_prefs.getString(_key) ?? AppConfig.defaultBrandId));

  final SharedPreferences _prefs;
  static const _key = 'brand_id';

  Future<void> select(Brand brand) async {
    if (brand.id == state.id) return;
    await _prefs.setString(_key, brand.id);
    emit(brand);
  }
}
