import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_app_template/src/core/network/models/app_error.dart';
import 'package:flutter_app_template/src/core/services/logger/logger.dart';
import 'package:fpdart/fpdart.dart';

/// Downloads an arbitrary image URL so it can be handed to any [ImagePromptRepo].
/// Kept provider-agnostic on purpose — every provider needs this, none owns it.
class ImageUrlFetcher {
  static final _log = getLogger('ImageUrlFetcher');

  /// Mirrors the cap enforced on picker-uploaded images (see [CreateView]) so a
  /// pasted URL can't bypass it and buffer an unbounded image into memory.
  static const maxBytes = 8 * 1024 * 1024;

  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 20),
  ));

  static Future<Either<AppError, (Uint8List, String)>> fetch(String url) async {
    final cancelToken = CancelToken();
    try {
      final response = await _dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (received > maxBytes) cancelToken.cancel('Image exceeds $maxBytes bytes');
        },
      );
      final bytes = Uint8List.fromList(response.data ?? []);
      if (bytes.isEmpty) return left(const AppError.unknown());
      if (bytes.lengthInBytes > maxBytes) {
        return left(const AppError.server(message: 'Image is too large (max 8MB).'));
      }

      final mimeType = response.headers.value('content-type')?.split(';').first.trim() ?? 'image/jpeg';
      return right((bytes, mimeType));
    } catch (e) {
      if (cancelToken.isCancelled) {
        return left(const AppError.server(message: 'Image is too large (max 8MB).'));
      }
      _log.e('[ERROR fetch] ${e.toString()}');
      return left(_mapException(e));
    }
  }

  /// Accurate, user-facing reason for a failed download — the generic
  /// [AppError.fromException] mapping reported timeouts for failures that were
  /// really bad status codes or connection errors.
  static AppError _mapException(Object e) {
    if (e is DioException) {
      final status = e.response?.statusCode;
      if (status != null) {
        return AppError.server(message: 'The URL returned HTTP $status.', statusCode: status);
      }
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          return const AppError.server(message: 'The download timed out.');
        case DioExceptionType.connectionError:
          return const AppError.server(message: 'No internet connection.');
        default:
          return const AppError.server(message: 'The URL could not be downloaded.');
      }
    }
    return const AppError.server(message: 'The URL could not be downloaded.');
  }
}
