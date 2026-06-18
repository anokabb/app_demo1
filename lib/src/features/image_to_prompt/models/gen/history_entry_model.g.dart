// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../history_entry_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HistoryEntryModel _$HistoryEntryModelFromJson(Map<String, dynamic> json) => HistoryEntryModel(
      id: json['id'] as String,
      prompt: json['prompt'] as String,
      mimeType: json['mimeType'] as String,
      tier: $enumDecode(_$ImagePromptModelTierEnumMap, json['tier'], unknownValue: ImagePromptModelTier.balanced),
      outputLanguage: json['outputLanguage'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isSaved: json['isSaved'] as bool? ?? false,
    );

Map<String, dynamic> _$HistoryEntryModelToJson(HistoryEntryModel instance) => <String, dynamic>{
      'id': instance.id,
      'prompt': instance.prompt,
      'mimeType': instance.mimeType,
      'tier': _$ImagePromptModelTierEnumMap[instance.tier]!,
      'outputLanguage': instance.outputLanguage,
      'createdAt': instance.createdAt.toIso8601String(),
      'isSaved': instance.isSaved,
    };

const _$ImagePromptModelTierEnumMap = {
  ImagePromptModelTier.fast: 'fast',
  ImagePromptModelTier.balanced: 'balanced',
  ImagePromptModelTier.detailed: 'detailed',
};
