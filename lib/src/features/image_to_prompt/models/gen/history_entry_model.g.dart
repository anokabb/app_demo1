// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../history_entry_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HistoryEntryModel _$HistoryEntryModelFromJson(Map<String, dynamic> json) =>
    HistoryEntryModel(
      id: json['id'] as String,
      prompt: json['prompt'] as String,
      mimeType: json['mime_type'] as String,
      tier: $enumDecode(_$ImagePromptModelTierEnumMap, json['tier'],
          unknownValue: ImagePromptModelTier.balanced),
      outputLanguage: json['output_language'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$HistoryEntryModelToJson(HistoryEntryModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'prompt': instance.prompt,
      'mime_type': instance.mimeType,
      'tier': _$ImagePromptModelTierEnumMap[instance.tier]!,
      'output_language': instance.outputLanguage,
      'created_at': instance.createdAt.toIso8601String(),
    };

const _$ImagePromptModelTierEnumMap = {
  ImagePromptModelTier.fast: 'fast',
  ImagePromptModelTier.balanced: 'balanced',
  ImagePromptModelTier.detailed: 'detailed',
};
