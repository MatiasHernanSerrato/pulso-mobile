import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulso_mobile/core/auth/token_storage.dart';
import 'package:pulso_mobile/core/network/auth_interceptor.dart';

class _FakeHandler extends RequestInterceptorHandler {
  RequestOptions? forwarded;
  @override
  void next(RequestOptions requestOptions) {
    forwarded = requestOptions;
  }
}

class _FakeErrorHandler extends ErrorInterceptorHandler {
  DioException? forwarded;
  @override
  void next(DioException err) {
    forwarded = err;
  }
}

void main() {
  group('AuthInterceptor', () {
    late InMemoryTokenStorage storage;
    late AuthInterceptor interceptor;

    setUp(() {
      storage = InMemoryTokenStorage();
      interceptor = AuthInterceptor(storage: storage);
    });

    test('no mete header si no hay token', () {
      final h = _FakeHandler();
      final req = RequestOptions(path: '/weights');
      interceptor.onRequest(req, h);
      expect(h.forwarded?.headers['Authorization'], isNull);
    });

    test('mete Bearer con el token guardado', () async {
      await storage.save(access: 'abc123', refresh: 'r1');
      final h = _FakeHandler();
      final req = RequestOptions(path: '/weights');
      interceptor.onRequest(req, h);
      expect(h.forwarded?.headers['Authorization'], 'Bearer abc123');
    });

    test('no mete Bearer en rutas publicas aunque haya token', () async {
      await storage.save(access: 'abc123', refresh: 'r1');
      final h = _FakeHandler();
      final req = RequestOptions(path: '/auth/login');
      interceptor.onRequest(req, h);
      expect(h.forwarded?.headers['Authorization'], isNull);
    });

    test('un 401 limpia la sesion', () async {
      await storage.save(access: 'abc123', refresh: 'r1');
      final h = _FakeErrorHandler();
      final req = RequestOptions(path: '/weights');
      final err = DioException(
        requestOptions: req,
        response: Response(requestOptions: req, statusCode: 401),
        type: DioExceptionType.badResponse,
      );
      interceptor.onError(err, h);
      expect(storage.isAuthenticated, isFalse);
    });

    test('401 en ruta publica no limpia el token', () async {
      await storage.save(access: 'abc123', refresh: 'r1');
      final h = _FakeErrorHandler();
      final req = RequestOptions(path: '/auth/login');
      final err = DioException(
        requestOptions: req,
        response: Response(requestOptions: req, statusCode: 401),
        type: DioExceptionType.badResponse,
      );
      interceptor.onError(err, h);
      expect(storage.isAuthenticated, isTrue);
    });
  });
}
