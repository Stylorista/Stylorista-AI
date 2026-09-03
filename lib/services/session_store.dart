import 'package:shared_preferences/shared_preferences.dart';

class SessionState {
  const SessionState({
    required this.authenticated,
    required this.welcomeCompleted,
  });

  const SessionState.signedOut()
    : authenticated = false,
      welcomeCompleted = false;

  final bool authenticated;
  final bool welcomeCompleted;
}

abstract interface class SessionStore {
  Future<SessionState> read();

  Future<void> setAuthenticated(bool value);

  Future<void> setWelcomeCompleted(bool value);
}

class PreferencesSessionStore implements SessionStore {
  PreferencesSessionStore({Future<SharedPreferences>? preferences})
    : _preferences = preferences ?? SharedPreferences.getInstance();

  static const _authenticatedKey = 'stylorista.authenticated';
  static const _welcomeCompletedKey = 'stylorista.welcome_completed';

  final Future<SharedPreferences> _preferences;

  @override
  Future<SessionState> read() async {
    final preferences = await _preferences;
    return SessionState(
      authenticated: preferences.getBool(_authenticatedKey) ?? false,
      welcomeCompleted: preferences.getBool(_welcomeCompletedKey) ?? false,
    );
  }

  @override
  Future<void> setAuthenticated(bool value) async {
    final preferences = await _preferences;
    await preferences.setBool(_authenticatedKey, value);
  }

  @override
  Future<void> setWelcomeCompleted(bool value) async {
    final preferences = await _preferences;
    await preferences.setBool(_welcomeCompletedKey, value);
  }
}

class MemorySessionStore implements SessionStore {
  MemorySessionStore({
    SessionState initialState = const SessionState.signedOut(),
  }) : _authenticated = initialState.authenticated,
       _welcomeCompleted = initialState.welcomeCompleted;

  bool _authenticated;
  bool _welcomeCompleted;

  @override
  Future<SessionState> read() async {
    return SessionState(
      authenticated: _authenticated,
      welcomeCompleted: _welcomeCompleted,
    );
  }

  @override
  Future<void> setAuthenticated(bool value) async {
    _authenticated = value;
  }

  @override
  Future<void> setWelcomeCompleted(bool value) async {
    _welcomeCompleted = value;
  }
}
