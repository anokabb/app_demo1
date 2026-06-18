import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_app_template/src/features/image_to_prompt/infrastructure/image_prompt_repo.dart';

class HistoryEntryModel {
  final String id;
  final String prompt;
  final String imageBase64;
  final String mimeType;
  final ImagePromptModelTier tier;
  final String outputLanguage;
  final DateTime createdAt;
  final bool isSaved;

  const HistoryEntryModel({
    required this.id,
    required this.prompt,
    required this.imageBase64,
    required this.mimeType,
    required this.tier,
    required this.outputLanguage,
    required this.createdAt,
    this.isSaved = false,
  });

  Uint8List get imageBytes => base64Decode(imageBase64);

  HistoryEntryModel copyWith({bool? isSaved}) {
    return HistoryEntryModel(
      id: id,
      prompt: prompt,
      imageBase64: imageBase64,
      mimeType: mimeType,
      tier: tier,
      outputLanguage: outputLanguage,
      createdAt: createdAt,
      isSaved: isSaved ?? this.isSaved,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'prompt': prompt,
        'imageBase64': imageBase64,
        'mimeType': mimeType,
        'tier': tier.name,
        'outputLanguage': outputLanguage,
        'createdAt': createdAt.toIso8601String(),
        'isSaved': isSaved,
      };

  factory HistoryEntryModel.fromJson(Map<String, dynamic> json) {
    return HistoryEntryModel(
      id: json['id'] as String,
      prompt: json['prompt'] as String,
      imageBase64: json['imageBase64'] as String,
      mimeType: json['mimeType'] as String,
      tier: ImagePromptModelTier.values.firstWhere(
        (t) => t.name == json['tier'],
        orElse: () => ImagePromptModelTier.balanced,
      ),
      outputLanguage: json['outputLanguage'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isSaved: json['isSaved'] as bool? ?? false,
    );
  }
}
