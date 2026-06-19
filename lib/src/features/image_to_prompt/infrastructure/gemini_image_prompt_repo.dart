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
  Future<Either<AppError, String>> generatePrompt({
    required Uint8List imageBytes,
    required String mimeType,
    required ImagePromptModelTier tier,
    required bool smartEnhance,
    required String outputLanguage,
  }) async {
    try {
      final apiKey = locator<RemoteConfigService>().data.settings.geminiApiKey;
      if (apiKey.isEmpty) {
        return left(const AppError.server(
          message: 'Missing Gemini API key. Set gemini_api_key in Remote Config.',
        ));
      }

      final modelId = _modelIds[tier]!;
      final instruction = _buildInstruction(
        smartEnhance: smartEnhance,
        outputLanguage: outputLanguage,
      );

      final response = await _dio.post(
        '/models/$modelId:generateContent',
        queryParameters: {'key': apiKey},
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
      );

      final data = response.data;
      final candidates = data is Map ? data['candidates'] as List? : null;
      if (candidates == null || candidates.isEmpty) {
        return left(const AppError.unknown());
      }

      final parts = (candidates.first as Map)['content']?['parts'] as List?;
      final text = parts?.map((p) => (p as Map)['text']?.toString() ?? '').join().trim();

      if (text == null || text.isEmpty) {
        return left(const AppError.unknown());
      }

      return right(text);
    } catch (e) {
      _log.e('[ERROR generatePrompt] ${e.toString()}');
      return left(AppError.fromException(e));
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
