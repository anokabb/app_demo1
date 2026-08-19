import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class DioFactory {
  static Dio create({
    required String baseUrl,
    List<Interceptor>? interceptors,
  }) {
    final options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    );

    final dio = Dio(options);

    dio.interceptors.addAll([
      if (interceptors != null) ...interceptors,
      // Request/response bodies contain the Gemini API key and base64 user
      // photos, so this interceptor must never be attached in release builds.
      if (kDebugMode)
        LogInterceptor(
          requestBody: true,
          responseBody: true,
        ),
    ]);

    return dio;
  }
}
