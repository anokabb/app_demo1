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
    // gemini-2.5-pro (the "detailed" tier) reasons before answering, so it can
    // take noticeably longer to start streaming than flash/flash-lite.
    ..options.receiveTimeout = const Duration(seconds: 90);

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
    final isDetailed = tier == ImagePromptModelTier.detailed;
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
            // Gemini 2.5 models spend output tokens on internal "thinking", so
            // the budget has to cover both the reasoning and the visible prompt.
            // gemini-2.5-pro thinks the most and cannot disable it, hence the
            // larger ceiling for the detailed tier.
            'maxOutputTokens': isDetailed ? 2048 : (smartEnhance ? 1024 : 512),
            // Turn thinking off for the fast/balanced tiers (they don't need it
            // for a short caption); pro requires a non-zero budget so give it a
            // bounded one that still leaves room for the actual answer.
            'thinkingConfig': {'thinkingBudget': isDetailed ? 1024 : 0},
          },
        },
        // Let non-2xx responses through instead of throwing — when the body is
        // a stream Dio can't parse the error JSON, so we drain and decode it
        // ourselves to surface Gemini's real message (quota, model access, …).
        options: Options(responseType: ResponseType.stream, validateStatus: (_) => true),
      );

      final status = response.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        final body = await response.data!.stream.cast<List<int>>().transform(utf8.decoder).join();
        yield left(AppError.server(message: _extractApiError(body, status), statusCode: status));
        return;
      }

      final buffer = StringBuffer();
      String? blockReason;
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

        // Capture why a response came back empty (safety filter, token cap…)
        // so we can report something more useful than a blank prompt.
        blockReason ??= (json?['promptFeedback'] as Map?)?['blockReason']?.toString();

        final candidates = json?['candidates'] as List?;
        if (candidates == null || candidates.isEmpty) continue;
        final first = candidates.first as Map;
        final finish = first['finishReason']?.toString();
        if (finish != null && finish != 'STOP' && finish != 'MAX_TOKENS') {
          blockReason ??= finish;
        }
        final parts = first['content']?['parts'] as List?;
        final delta = parts?.map((p) => (p as Map)['text']?.toString() ?? '').join() ?? '';
        if (delta.isEmpty) continue;

        buffer.write(delta);
        yield right(buffer.toString());
      }

      if (buffer.isEmpty) {
        yield left(AppError.server(
          message: blockReason != null
              ? 'The model returned no prompt (reason: $blockReason). Try another image or model.'
              : 'The model returned an empty prompt. Please try again.',
        ));
      }
    } catch (e) {
      _log.e('[ERROR generatePromptStream] ${e.toString()}');
      yield left(AppError.fromException(e));
    }
  }

  /// Pulls the human-readable message out of a Gemini error body, e.g.
  /// `{"error": {"code": 429, "message": "Quota exceeded…", "status": …}}`.
  String _extractApiError(String body, int status) {
    try {
      final decoded = jsonDecode(body);
      final error = decoded is Map ? decoded['error'] : (decoded is List && decoded.isNotEmpty ? decoded.first['error'] : null);
      final message = (error as Map?)?['message']?.toString();
      if (message != null && message.isNotEmpty) return message;
    } catch (_) {
      // fall through to the generic message
    }
    return 'Gemini request failed (HTTP $status).';
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
