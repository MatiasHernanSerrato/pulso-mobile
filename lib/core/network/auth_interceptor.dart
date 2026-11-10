import 'package:dio/dio.dart';

import '../auth/token_storage.dart';

/// Interceptor que mete el Bearer token en cada request salvo que la
/// ruta este marcada como publica. Tambien captura 401 para limpiar
/// la sesion.
///
/// No hago refresh automatico todavia; eso viene cuando tenga el
/// endpoint /auth/refresh del backend listo. Por ahora si el access
/// expira, el usuario rebota al login.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.storage,
    Set<String>? publicPaths,
    this.headerName = 'Authorization',
  }) : _publicPaths = publicPaths ?? const {'/auth/login', '/auth/register'};

  final TokenStorage storage;
  final Set<String> _publicPaths;
  final String headerName;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    if (_isPublic(options.path)) {
      return handler.next(options);
    }

    final token = storage.accessToken;
    if (token != null && token.isNotEmpty) {
      options.headers[headerName] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401 && !_isPublic(err.requestOptions.path)) {
      // sesion murio; dejo que el flujo de auth de app decida que hace
      // (navegar a login, mostrar snackbar, etc).
      storage.clear();
    }
    handler.next(err);
  }

  bool _isPublic(String path) {
    for (final p in _publicPaths) {
      if (path == p || path.endsWith(p)) return true;
    }
    return false;
  }
}
