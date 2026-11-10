import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/token_storage.dart';
import 'auth_interceptor.dart';

/// Base URL del pulso-api. En dev apunto al emulador android (10.0.2.2).
/// Cuando tenga deploy real lo paso a --dart-define.
const _defaultBaseUrl = String.fromEnvironment(
  'PULSO_API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8080',
);

final baseUrlProvider = Provider<String>((ref) => _defaultBaseUrl);

final dioProvider = Provider<Dio>((ref) {
  final baseUrl = ref.watch(baseUrlProvider);
  final storage = ref.watch(tokenStorageProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 10),
      headers: const {
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.add(AuthInterceptor(storage: storage));

  // Logger simple en debug. En release lo quito via kReleaseMode pero
  // lo dejo asi por ahora porque todavia no tengo observabilidad.
  dio.interceptors.add(
    LogInterceptor(
      requestBody: false,
      responseBody: false,
      requestHeader: false,
      responseHeader: false,
      logPrint: (obj) {
        // ignore: avoid_print
        print(obj);
      },
    ),
  );

  return dio;
});
