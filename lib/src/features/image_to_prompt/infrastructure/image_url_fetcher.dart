import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_app_template/src/core/network/models/app_error.dart';
import 'package:flutter_app_template/src/core/services/logger/logger.dart';
import 'package:fpdart/fpdart.dart';

/// Downloads an arbitrary image URL so it can be handed to any [ImagePromptRepo].
/// Kept provider-agnostic on purpose — every provider needs this, none owns it.
class ImageUrlFetcher {
  static final _log = getLogger('ImageUrlFetcher');

  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 20),
  ));

  static Future<Either<AppError, (Uint8List, String)>> fetch(String url) async {
    try {
      final response = await _dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = Uint8List.fromList(response.data ?? []);
      if (bytes.isEmpty) return left(const AppError.unknown());

      final mimeType = response.headers.value('content-type')?.split(';').first.trim() ?? 'image/jpeg';
      return right((bytes, mimeType));
    } catch (e) {
      _log.e('[ERROR fetch] ${e.toString()}');
      return left(AppError.fromException(e));
    }
  }
}
