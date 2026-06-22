import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_app_template/src/core/constants/hive_config.dart';
import 'package:flutter_app_template/src/core/extensions/context_extension.dart';
import 'package:flutter_app_template/src/core/services/locator/locator.dart';
import 'package:flutter_app_template/src/core/services/logger/logger.dart';
import 'package:flutter_app_template/src/core/services/purchases/subscription_cubit.dart';
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
      darkMode: settingsBox.get('itp_dark_mode', defaultValue: false),
      outputLanguage: settingsBox.get('itp_output_language', defaultValue: 'English'),
      selectedModel: ImagePromptModelTier.values.firstWhere(
        (t) => t.name == defaultTierName,
        orElse: () => ImagePromptModelTier.balanced,
      ),
    );
  }

  static String _imageKey(String id) => 'itp_image_$id';

  static List<HistoryEntryModel> _loadHistory() {
    final raw = persistsData.get(_historyKey);
    if (raw is! String || raw.isEmpty) return [];
    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      return list.map((json) {
        final entry = HistoryEntryModel.fromJson(json);
        final bytes = persistsData.get(_imageKey(entry.id));
        return entry.copyWith(imageBytes: bytes is Uint8List ? bytes : Uint8List(0));
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // Only lightweight metadata goes through jsonEncode here — images live under
  // their own Hive key (see [_imageKey]) so adding/removing one entry doesn't
  // re-serialize every other entry's image bytes.
  void _persistHistory(List<HistoryEntryModel> history) {
    persistsData.put(_historyKey, jsonEncode(history.map((e) => e.toJson()).toList()));
  }

  // ── image input ─────────────────────────────────────────────────────────

  void setPickedImage(Uint8List bytes, String mimeType) {
    emit(state.copyWith(pickedImageBytes: bytes, pickedImageMime: mimeType, imageUrl: '', genError: const Unset()));
  }

  void clearPickedImage() {
    emit(state.copyWith(pickedImageBytes: const Unset(), pickedImageMime: const Unset(), imageUrl: ''));
  }

  void setImageUrl(String url) {
    emit(state.copyWith(imageUrl: url.trim(), genError: const Unset()));
  }

  /// Called when the user explicitly pastes a URL (as opposed to typing one) —
  /// fetches it right away so the image shows in the preview immediately,
  /// instead of waiting until Generate is pressed.
  Future<void> pasteImageUrl(String url) async {
    final trimmed = url.trim();
    emit(state.copyWith(imageUrl: trimmed, genError: const Unset()));
    if (trimmed.isEmpty) return;

    emit(state.copyWith(isFetchingUrlPreview: true));
    final fetched = await ImageUrlFetcher.fetch(trimmed);
    emit(state.copyWith(isFetchingUrlPreview: false));
    fetched.fold(
      (_) => showTopAlert("Couldn't load that image URL.", isError: true),
      (data) => emit(state.copyWith(pickedImageBytes: data.$1, pickedImageMime: data.$2)),
    );
  }

  // ── options ─────────────────────────────────────────────────────────────

  void selectModel(ImagePromptModelTier tier) => emit(state.copyWith(selectedModel: tier));

  void setHistFilter(int index) => emit(state.copyWith(histFilter: index));

  void requestScrollToTop(int tabIndex) {
    emit(state.copyWith(scrollToTopTab: tabIndex, scrollToTopTick: state.scrollToTopTick + 1));
  }

  // Passing null clears the filter; the Unset sentinel forces copyWith to write
  // null rather than treating the omitted arg as "keep current value".
  void setHistTier(ImagePromptModelTier? tier) =>
      emit(state.copyWith(histTier: tier ?? const Unset()));

  void setHistLanguage(String? language) =>
      emit(state.copyWith(histLanguage: language ?? const Unset()));

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
    Uint8List? bytes;
    String mimeType = state.pickedImageMime ?? 'image/jpeg';

    final url = state.imageUrl.trim();

    // Validate there's something to generate from before spending a credit, so
    // an empty tap never decrements the free-tier allowance.
    if (url.isEmpty && state.pickedImageBytes == null) {
      showTopAlert('Upload an image or paste a URL first.', isError: true);
      return;
    }

    // Gate on the free-tier limit. Subscribers always pass; free users consume
    // one credit per generation and get the paywall once they hit the limit.
    final canGenerate = await locator<SubscriptionCubit>().canUseFreeAction();
    if (!canGenerate) return;

    if (url.isNotEmpty) {
      emit(state.copyWith(isGenerating: true, genError: const Unset(), showResult: false, resultSaved: false));

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
      bytes = state.pickedImageBytes;
      if (bytes == null) {
        showTopAlert('Upload an image or paste a URL first.', isError: true);
        return;
      }
      emit(state.copyWith(isGenerating: true, genError: const Unset(), showResult: false, resultSaved: false));
    }

    _log.i('Generating prompt — tier: ${state.selectedModel.name}, smartEnhance: ${state.smartEnhance}');

    final capturedBytes = bytes;
    final capturedMime = mimeType;

    String latestText = '';
    String? errorMessage;

    await _repo
        .generatePromptStream(
      imageBytes: bytes,
      mimeType: mimeType,
      tier: state.selectedModel,
      smartEnhance: state.smartEnhance,
      outputLanguage: state.outputLanguage,
    )
        .forEach((event) {
      event.fold(
        (error) => errorMessage = error.message,
        (text) {
          latestText = text;
          emit(state.copyWith(showResult: true, generatedPrompt: text));
        },
      );
    });

    if (errorMessage != null) {
      _log.e('[ERROR generate] $errorMessage');
      emit(state.copyWith(isGenerating: false, genError: errorMessage, showResult: false, generatedPrompt: ''));
      showTopAlert(errorMessage!, isError: true);
      return;
    }

    emit(state.copyWith(isGenerating: false));
    showTopAlert('Your prompt is ready!');
    if (state.autoSave) {
      await _addToHistory(latestText, capturedBytes, capturedMime);
      emit(state.copyWith(resultSaved: true));
    }
  }

  /// Manually saves the current result to history — used when auto-save is
  /// off and the user taps the Save action on the result card.
  Future<void> saveCurrentResult() async {
    final bytes = state.pickedImageBytes;
    if (bytes == null || state.generatedPrompt.isEmpty) return;
    await _addToHistory(state.generatedPrompt, bytes, state.pickedImageMime ?? 'image/jpeg');
    emit(state.copyWith(resultSaved: true));
    showTopAlert('Saved to history');
  }

  Future<void> _addToHistory(String prompt, Uint8List bytes, String mimeType) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final entry = HistoryEntryModel(
      id: id,
      prompt: prompt,
      mimeType: mimeType,
      tier: state.selectedModel,
      outputLanguage: state.outputLanguage,
      createdAt: DateTime.now(),
      imageBytes: bytes,
    );
    persistsData.put(_imageKey(id), bytes);

    final updated = [entry, ...state.history];
    if (updated.length > _maxHistoryEntries) {
      for (final dropped in updated.sublist(_maxHistoryEntries)) {
        persistsData.delete(_imageKey(dropped.id));
      }
      updated.removeRange(_maxHistoryEntries, updated.length);
    }
    _persistHistory(updated);
    emit(state.copyWith(history: updated));
  }

  void deleteHistoryEntry(String id) {
    HapticFeedback.mediumImpact();
    persistsData.delete(_imageKey(id));
    final updated = state.history.where((e) => e.id != id).toList();
    _persistHistory(updated);
    emit(state.copyWith(history: updated));
  }

  void deleteHistoryEntries(Iterable<String> ids) {
    HapticFeedback.mediumImpact();
    final idSet = ids.toSet();
    for (final id in idSet) {
      persistsData.delete(_imageKey(id));
    }
    final updated = state.history.where((e) => !idSet.contains(e.id)).toList();
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
      imageUrl: '',
      showResult: false,
      generatedPrompt: '',
    ));
    requestScrollToTop(0);
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

  void toggleDarkMode() {
    final value = !state.darkMode;
    emit(state.copyWith(darkMode: value));
    settingsBox.put('itp_dark_mode', value);
  }
}
