import 'package:shared_preferences/shared_preferences.dart';

/// Configuration management for CASEYA Supabase integration.
///
/// Priority:
/// 1. `--dart-define` compilation flags (recommended for production builds & Vercel)
///    `--dart-define=SUPABASE_URL=https://xyz.supabase.co`
///    `--dart-define=SUPABASE_ANON_KEY=eyJhbGci...`
/// 2. Locally stored SharedPreferences overrides (useful for development/testing without rebuilds)
class SupabaseConfig {
  // Compile-time environment constants passed via --dart-define
  static const String _envUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const String _envAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
  static const String _envPublishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY', defaultValue: '');

  static const String _prefsKeyUrl = 'caseya_supabase_url_override';
  static const String _prefsKeyAnonKey = 'caseya_supabase_anon_key_override';

  static String _activeUrl = '';
  static String _activeAnonKey = '';

  /// Initialize config from environment variables and local cache
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedUrl = prefs.getString(_prefsKeyUrl) ?? '';
      final cachedKey = prefs.getString(_prefsKeyAnonKey) ?? '';

      // Priority: Compile-time define -> Cached override
      if (_envUrl.isNotEmpty) {
        _activeUrl = _envUrl.trim();
      } else if (cachedUrl.isNotEmpty) {
        _activeUrl = cachedUrl.trim();
      } else {
        _activeUrl = '';
      }

      if (_envAnonKey.isNotEmpty) {
        _activeAnonKey = _envAnonKey.trim();
      } else if (_envPublishableKey.isNotEmpty) {
        _activeAnonKey = _envPublishableKey.trim();
      } else if (cachedKey.isNotEmpty) {
        _activeAnonKey = cachedKey.trim();
      } else {
        _activeAnonKey = '';
      }
    } catch (_) {
      _activeUrl = _envUrl.isNotEmpty ? _envUrl.trim() : '';
      _activeAnonKey = _envAnonKey.isNotEmpty ? _envAnonKey.trim() : _envPublishableKey.trim();
    }
  }

  /// The active Supabase Project URL
  static String get url => _activeUrl;

  /// The active Supabase Anonymous/Publishable Key (safe for browser client)
  static String get anonKey => _activeAnonKey;

  /// Whether Supabase configuration is present and valid
  static bool get isConfigured {
    if (_activeUrl.isEmpty || _activeAnonKey.isEmpty) return false;
    final uri = Uri.tryParse(_activeUrl);
    return uri != null && uri.hasScheme && uri.host.isNotEmpty;
  }

  /// Save runtime override to local storage (for testing/setup)
  static Future<void> saveOverrides({required String url, required String anonKey}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKeyUrl, url.trim());
    await prefs.setString(_prefsKeyAnonKey, anonKey.trim());
    _activeUrl = url.trim();
    _activeAnonKey = anonKey.trim();
  }

  /// Clear runtime overrides
  static Future<void> clearOverrides() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKeyUrl);
    await prefs.remove(_prefsKeyAnonKey);
    _activeUrl = _envUrl.isNotEmpty ? _envUrl.trim() : '';
    _activeAnonKey = _envAnonKey.isNotEmpty ? _envAnonKey.trim() : _envPublishableKey.trim();
  }

  /// Masked URL for safe UI display without revealing complete project identifiers
  static String get maskedUrl {
    if (_activeUrl.isEmpty) return 'Not configured';
    try {
      final uri = Uri.parse(_activeUrl);
      final host = uri.host;
      if (host.length > 12) {
        return '${host.substring(0, 6)}...${host.substring(host.length - 8)}';
      }
      return host;
    } catch (_) {
      return 'Configured';
    }
  }
}
