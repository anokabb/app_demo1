import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_app_template/src/core/network/client/dio_factory.dart';
import 'package:flutter_app_template/src/core/network/client/interceptors/logger_interceptor.dart';
import 'package:flutter_app_template/src/core/network/models/app_error.dart';
import 'package:flutter_app_template/src/core/services/locator/locator.dart';
import 'package:flutter_app_template/src/core/services/logger/logger.dart';
import 'package:flutter_app_template/src/core/services/remote_config/remote_config_service.dart';
import 'package:flutter_app_template/src/features/image_to_prompt/infrastructure/image_prompt_repo.dart';
import 'package:fpdart/fpdart.dart';

class GeminiImagePromptRepo implements ImagePromptRepo {
  final _log = getLogger('GeminiImagePromptRepo');

  final Dio _dio = DioFactory.create(
    baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
    interceptors: [LoggerInterceptor()],
  )..options.connectTimeout = const Duration(seconds: 30)
    ..options.receiveTimeout = const Duration(seconds: 45);

  static const _modelIds = {
    ImagePromptModelTier.fast: 'gemini-2.5-flash-lite',
    ImagePromptModelTier.balanced: 'gemini-2.5-flash',
    ImagePromptModelTier.detailed: 'gemini-2.5-pro',
  };

  @override
  Stream<Either<AppError, String>> generatePromptStream({
    required Uint8List imageBytes,
    required String mimeType,
    required ImagePromptModelTier tier,
    required bool smartEnhance,
    required String outputLanguage,
  }) async* {
    final apiKey = locator<RemoteConfigService>().data.settings.geminiApiKey;
    if (apiKey.isEmpty) {
      yield left(const AppError.server(
        message: 'Missing Gemini API key. Set gemini_api_key in Remote Config.',
      ));
      return;
    }

    final modelId = _modelIds[tier]!;
    final instruction = _buildInstruction(
      smartEnhance: smartEnhance,
      outputLanguage: outputLanguage,
    );

    try {
      final response = await _dio.post<ResponseBody>(
        '/models/$modelId:streamGenerateContent',
        queryParameters: {'key': apiKey, 'alt': 'sse'},
        data: {
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': instruction},
                {
                  'inline_data': {
                    'mime_type': mimeType,
                    'data': base64Encode(imageBytes),
                  },
                },
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.55,
            'maxOutputTokens': smartEnhance ? 400 : 180,
          },
        },
        options: Options(responseType: ResponseType.stream),
      );

      final buffer = StringBuffer();
      final lines = response.data!.stream
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in lines) {
        if (!line.startsWith('data:')) continue;
        final payload = line.substring(5).trim();
        if (payload.isEmpty) continue;

        Map? json;
        try {
          json = jsonDecode(payload) as Map?;
        } catch (_) {
          continue; // partial/malformed SSE chunk — wait for the rest
        }

        final candidates = json?['candidates'] as List?;
        if (candidates == null || candidates.isEmpty) continue;
        final parts = (candidates.first as Map)['content']?['parts'] as List?;
        final delta = parts?.map((p) => (p as Map)['text']?.toString() ?? '').join() ?? '';
        if (delta.isEmpty) continue;

        buffer.write(delta);
        yield right(buffer.toString());
      }

      if (buffer.isEmpty) {
        yield left(const AppError.unknown());
      }
    } catch (e) {
      _log.e('[ERROR generatePromptStream] ${e.toString()}');
      yield left(AppError.fromException(e));
    }
  }

  String _buildInstruction({
    required bool smartEnhance,
    required String outputLanguage,
  }) {
    final buffer = StringBuffer(
      'You are an expert prompt engineer for AI image generators such as Midjourney, Stable Diffusion and DALL-E. '
      'Study the attached image carefully and write ONE single descriptive prompt that could be used to recreate it. '
      'Cover subject, setting, composition, lighting, color palette, mood, and art style or photographic technique. '
      'Respond with ONLY the prompt text as a single paragraph — no preamble, no quotation marks, no markdown, no labels.',
    );

    buffer.write(smartEnhance
        ? ' Make the prompt vivid, richly detailed and evocative, around 60-90 words.'
        : ' Keep the prompt concise and literal, around 25-40 words, focusing on the essential visual elements only.');

    buffer.write(' Write the prompt in $outputLanguage.');

    return buffer.toString();
  }
}
