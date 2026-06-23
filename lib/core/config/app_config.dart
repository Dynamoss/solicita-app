/// Centralised, compile-time configuration.
///
/// Every value can be overridden at build/run time via `--dart-define`, e.g.:
///
/// ```
/// flutter run \
///   --dart-define=API_BASE_URL=http://10.0.2.2:3000 \
///   --dart-define=AI_API_KEY=sk-... \
///   --dart-define=BRAND=corporate
/// ```
///
/// Keeping secrets out of source (passed via `--dart-define`) is the reason
/// there is no committed `.env` with a real key.
class AppConfig {
  const AppConfig._();

  /// Base URL of the mock REST API (json-server). Defaults to `localhost`.
  ///
  /// IMPORTANT: the Android emulator cannot reach the host's `localhost`; use
  /// `http://10.0.2.2:3000` there (documented in the README).
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  /// API key for the optional LLM provider. When empty, the app transparently
  /// falls back to a deterministic on-device suggestion engine.
  static const String aiApiKey = String.fromEnvironment('AI_API_KEY');

  static const String aiBaseUrl = String.fromEnvironment(
    'AI_BASE_URL',
    defaultValue: 'https://api.anthropic.com/v1/messages',
  );

  static const String aiModel = String.fromEnvironment(
    'AI_MODEL',
    defaultValue: 'claude-haiku-4-5',
  );

  /// Initial whitelabel brand id (see `Brands`). Can also be changed at runtime
  /// from the UI; this is only the default on first launch.
  static const String defaultBrandId = String.fromEnvironment(
    'BRAND',
    defaultValue: 'saude',
  );

  /// Page size used for the paginated requests list.
  static const int pageSize = 10;

  static bool get hasAiKey => aiApiKey.isNotEmpty;
}
