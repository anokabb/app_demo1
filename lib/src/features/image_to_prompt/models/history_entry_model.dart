import 'dart:typed_data';

import 'package:flutter_app_template/src/features/image_to_prompt/infrastructure/image_prompt_repo.dart';
import 'package:json_annotation/json_annotation.dart';

part 'gen/history_entry_model.g.dart';

/// [imageBytes] is persisted separately (keyed by [id], see [ImageToPromptCubit])
/// instead of being inlined as base64 here — keeping it out of the JSON index
/// is what stops every history mutation from re-serializing every stored image.
@JsonSerializable()
class HistoryEntryModel {
  final String id;
  final String prompt;
  final String mimeType;
  @JsonKey(unknownEnumValue: ImagePromptModelTier.balanced)
  final ImagePromptModelTier tier;
  final String outputLanguage;
  final DateTime createdAt;
  @JsonKey(defaultValue: false)
  final bool isSaved;
  @JsonKey(includeFromJson: false, includeToJson: false)
  final Uint8List? imageBytes;

  const HistoryEntryModel({
    required this.id,
    required this.prompt,
    required this.mimeType,
    required this.tier,
    required this.outputLanguage,
    required this.createdAt,
    this.isSaved = false,
    this.imageBytes,
  });

  factory HistoryEntryModel.fromJson(Map<String, dynamic> json) => _$HistoryEntryModelFromJson(json);

  Map<String, dynamic> toJson() => _$HistoryEntryModelToJson(this);

  HistoryEntryModel copyWith({bool? isSaved, Uint8List? imageBytes}) {
    return HistoryEntryModel(
      id: id,
      prompt: prompt,
      mimeType: mimeType,
      tier: tier,
      outputLanguage: outputLanguage,
      createdAt: createdAt,
      isSaved: isSaved ?? this.isSaved,
      imageBytes: imageBytes ?? this.imageBytes,
    );
  }
}
