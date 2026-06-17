import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_app_template/src/core/services/logger/logger.dart';

part 'gen/image_to_prompt_cubit.freezed.dart';
part 'image_to_prompt_state.dart';

class ImageToPromptCubit extends Cubit<ImageToPromptState> {
  // ignore: unused_field
  final _log = getLogger('ImageToPromptCubit');

  ImageToPromptCubit() : super(const ImageToPromptState());

  void selectModel(int index) => emit(state.copyWith(selectedModel: index));

  void setHistFilter(int index) => emit(state.copyWith(histFilter: index));

  void generate() => emit(state.copyWith(showResult: true));

  void copyResult() {
    emit(state.copyWith(resultCopied: true));
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!isClosed) emit(state.copyWith(resultCopied: false));
    });
  }

  void copyRecent(int index) {
    emit(state.copyWith(recentCopied: index));
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!isClosed) emit(state.copyWith(recentCopied: -1));
    });
  }

  void copyHistory(int index) {
    emit(state.copyWith(histCopied: index));
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!isClosed) emit(state.copyWith(histCopied: -1));
    });
  }

  void toggleAutoSave() => emit(state.copyWith(autoSave: !state.autoSave));
  void toggleSmartEnhance() => emit(state.copyWith(smartEnhance: !state.smartEnhance));
  void toggleNotifications() => emit(state.copyWith(notifications: !state.notifications));
  void toggleDarkMode() => emit(state.copyWith(darkMode: !state.darkMode));
}
