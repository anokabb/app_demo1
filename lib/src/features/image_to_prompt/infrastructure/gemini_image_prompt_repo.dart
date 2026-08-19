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
    ..options.receiveTimeout = const Duration(seconds: 90);

  // All tiers use the same (widely available) model. The Fast/Balanced/Detailed
  // tier only changes how the generated prompt should look — its depth and
  // length — not which model runs. gemini-2.5-pro was intentionally dropped
  // here because it is no longer available to new API users.
  static const _modelId = 'gemini-2.5-flash';

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

    final instruction = _buildInstruction(
      tier: tier,
      smartEnhance: smartEnhance,
      outputLanguage: outputLanguage,
    );

    try {
      final response = await _dio.post<ResponseBody>(
        '/models/$_modelId:streamGenerateContent',
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
            // Give the more detailed tiers a larger output ceiling so the longer
            // prompt has room to finish. Thinking stays off for every tier — the
            // depth difference comes from the instruction, not internal reasoning.
            'maxOutputTokens': _maxOutputTokens(tier),
            'thinkingConfig': {'thinkingBudget': 0},
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

  /// Output-token ceiling per tier — larger tiers produce longer prompts and
  /// need more room to finish. Same model for all; only the budget differs.
  int _maxOutputTokens(ImagePromptModelTier tier) {
    switch (tier) {
      case ImagePromptModelTier.fast:
        return 512;
      case ImagePromptModelTier.balanced:
        return 1024;
      case ImagePromptModelTier.detailed:
        return 2048;
    }
  }

  /// The tier controls how the generated prompt should *look* — its depth and
  /// length — while smartEnhance layers on extra vividness. Same model runs for
  /// every tier.
  String _tierStyle(ImagePromptModelTier tier) {
    switch (tier) {
      case ImagePromptModelTier.fast:
        return ' Keep the prompt concise and literal, around 20-30 words, focusing only on the essential visual elements.';
      case ImagePromptModelTier.balanced:
        return ' Write a balanced, moderately detailed prompt, around 45-65 words, covering the main subject and key stylistic details.';
      case ImagePromptModelTier.detailed:
        return ' Write a comprehensive, richly detailed prompt, around 90-130 words, thoroughly describing every notable aspect of the image.';
    }
  }

  String _buildInstruction({
    required ImagePromptModelTier tier,
    required bool smartEnhance,
    required String outputLanguage,
  }) {
    final buffer = StringBuffer(
      'You are an expert prompt engineer for AI image generators such as Midjourney, Stable Diffusion and DALL-E. '
      'Study the attached image carefully and write ONE single descriptive prompt that could be used to recreate it. '
      'Cover subject, setting, composition, lighting, color palette, mood, and art style or photographic technique. '
      'Respond with ONLY the prompt text as a single paragraph — no preamble, no quotation marks, no markdown, no labels.',
    );

    buffer.write(_tierStyle(tier));

    if (smartEnhance) {
      buffer.write(' Use vivid, evocative language and creative flourishes to make the prompt especially compelling.');
    }

    buffer.write(' Write the prompt in $outputLanguage.');

    return buffer.toString();
  }
}
