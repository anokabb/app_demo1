import 'dart:typed_data';

import 'package:flutter_app_template/src/core/network/models/app_error.dart';
import 'package:fpdart/fpdart.dart';

enum ImagePromptModelTier { fast, balanced, detailed }

extension ImagePromptModelTierX on ImagePromptModelTier {
  String get label {
    switch (this) {
      case ImagePromptModelTier.fast:
        return 'FAST';
      case ImagePromptModelTier.balanced:
        return 'BALANCED';
      case ImagePromptModelTier.detailed:
        return 'DETAILED';
    }
  }

  String get description {
    switch (this) {
      case ImagePromptModelTier.fast:
        return 'Quickest turnaround, great for drafts';
      case ImagePromptModelTier.balanced:
        return 'Best mix of speed and detail';
      case ImagePromptModelTier.detailed:
        return 'Slowest, most thorough description';
    }
  }
}

/// Provider-agnostic contract for turning an image into an AI-image-generator prompt.
///
/// Swap providers by registering a different implementation for this type in
/// `locator.dart` — every other line in the app talks to `ImagePromptRepo`
/// only, never to a concrete provider class.
abstract class ImagePromptRepo {
  Future<Either<AppError, String>> generatePrompt({
    required Uint8List imageBytes,
    required String mimeType,
    required ImagePromptModelTier tier,
    required bool smartEnhance,
    required String outputLanguage,
  });
}
