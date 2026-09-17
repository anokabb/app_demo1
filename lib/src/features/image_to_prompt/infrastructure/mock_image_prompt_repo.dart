import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_app_template/src/core/network/models/app_error.dart';
import 'package:flutter_app_template/src/core/services/logger/logger.dart';
import 'package:flutter_app_template/src/features/image_to_prompt/infrastructure/image_prompt_repo.dart';
import 'package:fpdart/fpdart.dart';

/// A fake [ImagePromptRepo] for local testing — no network, no API key.
///
/// Returns a plausible, varied prompt after a short simulated delay so the
/// generate → result → history flow can be exercised end-to-end. Swap this
/// for a real provider (e.g. `GeminiImagePromptRepo`) in `locator.dart`.
class MockImagePromptRepo implements ImagePromptRepo {
  final _log = getLogger('MockImagePromptRepo');
  final _rand = Random();

  static const _subjects = [
    'a serene mountain lake at dawn',
    'a futuristic neon-lit city street in the rain',
    'a cozy reading nook with warm sunlight',
    'a majestic lion resting on a savanna rock',
    'an astronaut floating above a glowing planet',
    'a vintage coffee shop interior, soft bokeh',
    'a misty forest path with towering pines',
    'a vibrant coral reef teeming with fish',
  ];

  static const _styles = [
    'cinematic photography, 35mm, shallow depth of field',
    'digital illustration, vibrant colors, highly detailed',
    'oil painting, impressionist brush strokes',
    'concept art, dramatic lighting, ArtStation trending',
    'hyperrealistic render, octane, volumetric light',
  ];

  static const _details = [
    'golden hour lighting, soft shadows, 8k, ultra detailed',
    'moody atmosphere, rich contrast, intricate textures',
    'wide-angle composition, balanced symmetry, award-winning',
    'dynamic perspective, rim lighting, professional color grading',
  ];

  @override
  Stream<Either<AppError, String>> generatePromptStream({
    required Uint8List imageBytes,
    required String mimeType,
    required ImagePromptModelTier tier,
    required bool smartEnhance,
    required String outputLanguage,
  }) async* {
    _log.i('[MOCK] generatePromptStream tier=${tier.name} lang=$outputLanguage bytes=${imageBytes.length}');

    final subject = _subjects[_rand.nextInt(_subjects.length)];
    final style = _styles[_rand.nextInt(_styles.length)];

    final buffer = StringBuffer('$subject, $style');
    if (smartEnhance || tier == ImagePromptModelTier.detailed) {
      buffer.write(', ${_details[_rand.nextInt(_details.length)]}');
    }
    if (tier == ImagePromptModelTier.detailed) {
      buffer.write(', masterpiece, best quality, sharp focus');
    }
    if (outputLanguage.toLowerCase() != 'english') {
      buffer.write(' [output language: $outputLanguage]');
    }

    // Simulate token-by-token streaming, word by word — faster tiers stream quicker.
    final delayMs = switch (tier) {
      ImagePromptModelTier.fast => 40,
      ImagePromptModelTier.balanced => 70,
      ImagePromptModelTier.detailed => 100,
    };

    final words = buffer.toString().split(' ');
    final streamed = StringBuffer();
    for (var i = 0; i < words.length; i++) {
      await Future.delayed(Duration(milliseconds: delayMs + _rand.nextInt(40)));
      if (i > 0) streamed.write(' ');
      streamed.write(words[i]);
      yield Right(streamed.toString());
    }
  }
}
