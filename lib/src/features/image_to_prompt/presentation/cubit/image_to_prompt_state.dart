part of 'image_to_prompt_cubit.dart';

@freezed
class ImageToPromptState with _$ImageToPromptState {
  const factory ImageToPromptState({
    @Default(0) int selectedModel,
    @Default(false) bool showResult,
    @Default(false) bool resultCopied,
    @Default(-1) int recentCopied,
    @Default(0) int histFilter,
    @Default(-1) int histCopied,
    @Default(true) bool autoSave,
    @Default(true) bool smartEnhance,
    @Default(true) bool notifications,
    @Default(false) bool darkMode,
  }) = _ImageToPromptState;
}
