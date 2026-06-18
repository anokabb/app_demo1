import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_app_template/src/core/constants/hive_config.dart';
import 'package:flutter_app_template/src/core/extensions/context_extension.dart';
import 'package:flutter_app_template/src/core/services/locator/locator.dart';
import 'package:flutter_app_template/src/core/services/logger/logger.dart';
import 'package:flutter_app_template/src/features/image_to_prompt/infrastructure/image_prompt_repo.dart';
import 'package:flutter_app_template/src/features/image_to_prompt/infrastructure/image_url_fetcher.dart';
import 'package:flutter_app_template/src/features/image_to_prompt/models/history_entry_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'image_to_prompt_state.dart';

class ImageToPromptCubit extends Cubit<ImageToPromptState> {
  final _log = getLogger('ImageToPromptCubit');
  final ImagePromptRepo _repo = locator<ImagePromptRepo>();

  static const _historyKey = 'image_to_prompt_history';
  static const _maxHistoryEntries = 60;

  ImageToPromptCubit() : super(_initialState());

  static ImageToPromptState _initialState() {
    final defaultTierName = settingsBox.get('itp_default_model', defaultValue: ImagePromptModelTier.balanced.name);
    return ImageToPromptState(
      history: _loadHistory(),
      autoSave: settingsBox.get('itp_auto_save', defaultValue: true),
      smartEnhance: settingsBox.get('itp_smart_enhance', defaultValue: true),
      notifications: settingsBox.get('itp_notifications', defaultValue: true),
      darkMode: settingsBox.get('itp_dark_mode', defaultValue: false),
      outputLanguage: settingsBox.get('itp_output_language', defaultValue: 'English'),
      selectedModel: ImagePromptModelTier.values.firstWhere(
        (t) => t.name == defaultTierName,
        orElse: () => ImagePromptModelTier.balanced,
      ),
    );
  }

  static List<HistoryEntryModel> _loadHistory() {
    final raw = persistsData.get(_historyKey);
    if (raw is! String || raw.isEmpty) return [];
    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      return list.map(HistoryEntryModel.fromJson).toList();
    } catch (_) {
      return [];
    }
  }

  void _persistHistory(List<HistoryEntryModel> history) {
    persistsData.put(_historyKey, jsonEncode(history.map((e) => e.toJson()).toList()));
  }

  // ── image input ─────────────────────────────────────────────────────────

  void setPickedImage(Uint8List bytes, String mimeType) {
    emit(state.copyWith(pickedImageBytes: bytes, pickedImageMime: mimeType, imageUrl: '', genError: const Unset()));
  }

  void clearPickedImage() {
    emit(state.copyWith(pickedImageBytes: const Unset(), pickedImageMime: const Unset()));
  }

  void setImageUrl(String url) {
    if (url.trim().isNotEmpty) {
      emit(state.copyWith(
        imageUrl: url,
        pickedImageBytes: const Unset(),
        pickedImageMime: const Unset(),
        genError: const Unset(),
      ));
    } else {
      emit(state.copyWith(imageUrl: url, genError: const Unset()));
    }
  }

  // ── options ─────────────────────────────────────────────────────────────

  void selectModel(ImagePromptModelTier tier) => emit(state.copyWith(selectedModel: tier));

  void setHistFilter(int index) => emit(state.copyWith(histFilter: index));

  void setHistorySearch(String query) => emit(state.copyWith(historySearch: query));

  void setOutputLanguage(String language) {
    emit(state.copyWith(outputLanguage: language));
    settingsBox.put('itp_output_language', language);
  }

  void setDefaultModel(ImagePromptModelTier tier) {
    emit(state.copyWith(selectedModel: tier));
    settingsBox.put('itp_default_model', tier.name);
  }

  // ── generation ──────────────────────────────────────────────────────────

  Future<void> generate() async {
    Uint8List? bytes = state.pickedImageBytes;
    String mimeType = state.pickedImageMime ?? 'image/jpeg';

    if (bytes == null) {
      final url = state.imageUrl.trim();
      if (url.isEmpty) {
        showTopAlert('Upload an image or paste a URL first.', isError: true);
        return;
      }

      emit(state.copyWith(isGenerating: true, genError: const Unset(), showResult: false));

      final fetched = await ImageUrlFetcher.fetch(url);
      final fetchedData = fetched.fold<(Uint8List, String)?>((_) => null, (data) => data);
      if (fetchedData == null) {
        emit(state.copyWith(isGenerating: false));
        showTopAlert("Couldn't load that image URL.", isError: true);
        return;
      }

      bytes = fetchedData.$1;
      mimeType = fetchedData.$2;
      emit(state.copyWith(pickedImageBytes: bytes, pickedImageMime: mimeType));
    } else {
      emit(state.copyWith(isGenerating: true, genError: const Unset(), showResult: false));
    }

    _log.i('Generating prompt — tier: ${state.selectedModel.name}, smartEnhance: ${state.smartEnhance}');

    final result = await _repo.generatePrompt(
      imageBytes: bytes,
      mimeType: mimeType,
      tier: state.selectedModel,
      smartEnhance: state.smartEnhance,
      outputLanguage: state.outputLanguage,
    );

    final capturedBytes = bytes;
    final capturedMime = mimeType;

    await result.fold(
      (error) async {
        _log.e('[ERROR generate] ${error.message}');
        emit(state.copyWith(isGenerating: false, genError: error.message));
        showTopAlert(error.message, isError: true);
      },
      (prompt) async {
        emit(state.copyWith(isGenerating: false, showResult: true, generatedPrompt: prompt));
        if (state.notifications) showTopAlert('Your prompt is ready!');
        if (state.autoSave) {
          await _addToHistory(prompt, capturedBytes, capturedMime);
        }
      },
    );
  }

  Future<void> saveCurrentToHistory() async {
    if (state.generatedPrompt.isEmpty || state.pickedImageBytes == null) return;
    await _addToHistory(state.generatedPrompt, state.pickedImageBytes!, state.pickedImageMime ?? 'image/jpeg');
    showTopAlert('Saved to history');
  }

  Future<void> _addToHistory(String prompt, Uint8List bytes, String mimeType) async {
    final entry = HistoryEntryModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      prompt: prompt,
      imageBase64: base64Encode(bytes),
      mimeType: mimeType,
      tier: state.selectedModel,
      outputLanguage: state.outputLanguage,
      createdAt: DateTime.now(),
    );
    final updated = [entry, ...state.history];
    if (updated.length > _maxHistoryEntries) {
      updated.removeRange(_maxHistoryEntries, updated.length);
    }
    _persistHistory(updated);
    emit(state.copyWith(history: updated));
  }

  void deleteHistoryEntry(String id) {
    final updated = state.history.where((e) => e.id != id).toList();
    _persistHistory(updated);
    emit(state.copyWith(history: updated));
  }

  void toggleHistorySaved(String id) {
    final updated = state.history.map((e) => e.id == id ? e.copyWith(isSaved: !e.isSaved) : e).toList();
    _persistHistory(updated);
    emit(state.copyWith(history: updated));
  }

  void useHistoryEntry(String id) {
    HistoryEntryModel? entry;
    for (final e in state.history) {
      if (e.id == id) {
        entry = e;
        break;
      }
    }
    if (entry == null) return;
    emit(state.copyWith(
      pickedImageBytes: entry.imageBytes,
      pickedImageMime: entry.mimeType,
      generatedPrompt: entry.prompt,
      showResult: true,
      imageUrl: '',
    ));
  }

  // ── copy feedback flags ─────────────────────────────────────────────────

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

  // ── settings ────────────────────────────────────────────────────────────

  void toggleAutoSave() {
    final value = !state.autoSave;
    emit(state.copyWith(autoSave: value));
    settingsBox.put('itp_auto_save', value);
  }

  void toggleSmartEnhance() {
    final value = !state.smartEnhance;
    emit(state.copyWith(smartEnhance: value));
    settingsBox.put('itp_smart_enhance', value);
  }

  void toggleNotifications() {
    final value = !state.notifications;
    emit(state.copyWith(notifications: value));
    settingsBox.put('itp_notifications', value);
  }

  void toggleDarkMode() {
    final value = !state.darkMode;
    emit(state.copyWith(darkMode: value));
    settingsBox.put('itp_dark_mode', value);
  }
}
