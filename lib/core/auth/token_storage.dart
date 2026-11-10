import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Guarda el access token / refresh token para la sesion actual.
///
/// La version en memoria es la que uso ahora (test y dev). Para prod
/// tengo que meter una implementacion encima de flutter_secure_storage,
/// pero quiero commitear la interfaz primero asi el interceptor no
/// depende del paquete nativo mientras armo el flujo de auth.
abstract class TokenStorage {
  /// Access token vigente, o null si no hay sesion. Debe ser sincrono
  /// porque el interceptor lo necesita para armar cada request sin
  /// agregar overhead; si hace falta IO (secure storage async), la
  /// implementacion hace prefetch al arranque.
  String? get accessToken;

  String? get refreshToken;

  /// true si tenemos credenciales cargadas, aunque sean viejas.
  bool get isAuthenticated;

  Future<void> save({required String access, required String refresh});

  Future<void> clear();
}

/// Implementacion in memory. Sobrevive al hot reload gracias a riverpod
/// (el provider es keepAlive por default) pero se pierde al matar la
/// app. Suficiente para ahora.
class InMemoryTokenStorage implements TokenStorage {
  String? _access;
  String? _refresh;

  @override
  String? get accessToken => _access;

  @override
  String? get refreshToken => _refresh;

  @override
  bool get isAuthenticated => _access != null;

  @override
  Future<void> save({required String access, required String refresh}) async {
    _access = access;
    _refresh = refresh;
  }

  @override
  Future<void> clear() async {
    _access = null;
    _refresh = null;
  }
}

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return InMemoryTokenStorage();
});
