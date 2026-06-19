part of 'image_to_prompt_cubit.dart';

/// Sentinel used by [ImageToPromptState.copyWith] so nullable fields
/// (picked image, generation error) can be explicitly reset to null —
/// a plain `null` argument means "leave unchanged".
class Unset {
  const Unset();
}

/// Default value for copyWith's nullable-field params — distinct from [Unset]
/// so "field omitted" (keep current value) can be told apart from an
/// explicit `Unset()` (reset to null).
const _unspecified = Object();

class ImageToPromptState {
  final ImagePromptModelTier selectedModel;
  final Uint8List? pickedImageBytes;
  final String? pickedImageMime;
  final String imageUrl;
  final bool isGenerating;
  final String generatedPrompt;
  final String? genError;
  final bool showResult;
  final bool resultCopied;
  final int recentCopied;
  final int histFilter;
  final String historySearch;
  final int histCopied;
  final List<HistoryEntryModel> history;
  final bool autoSave;
  final bool smartEnhance;
  final bool darkMode;
  final String outputLanguage;

  const ImageToPromptState({
    this.selectedModel = ImagePromptModelTier.balanced,
    this.pickedImageBytes,
    this.pickedImageMime,
    this.imageUrl = '',
    this.isGenerating = false,
    this.generatedPrompt = '',
    this.genError,
    this.showResult = false,
    this.resultCopied = false,
    this.recentCopied = -1,
    this.histFilter = 0,
    this.historySearch = '',
    this.histCopied = -1,
    this.history = const [],
    this.autoSave = true,
    this.smartEnhance = true,
    this.darkMode = false,
    this.outputLanguage = 'English',
  });

  ImageToPromptState copyWith({
    ImagePromptModelTier? selectedModel,
    Object? pickedImageBytes = _unspecified,
    Object? pickedImageMime = _unspecified,
    String? imageUrl,
    bool? isGenerating,
    String? generatedPrompt,
    Object? genError = _unspecified,
    bool? showResult,
    bool? resultCopied,
    int? recentCopied,
    int? histFilter,
    String? historySearch,
    int? histCopied,
    List<HistoryEntryModel>? history,
    bool? autoSave,
    bool? smartEnhance,
    bool? darkMode,
    String? outputLanguage,
  }) {
    return ImageToPromptState(
      selectedModel: selectedModel ?? this.selectedModel,
      pickedImageBytes: pickedImageBytes == _unspecified
          ? this.pickedImageBytes
          : (pickedImageBytes is Unset ? null : pickedImageBytes as Uint8List?),
      pickedImageMime: pickedImageMime == _unspecified
          ? this.pickedImageMime
          : (pickedImageMime is Unset ? null : pickedImageMime as String?),
      imageUrl: imageUrl ?? this.imageUrl,
      isGenerating: isGenerating ?? this.isGenerating,
      generatedPrompt: generatedPrompt ?? this.generatedPrompt,
      genError: genError == _unspecified ? this.genError : (genError is Unset ? null : genError as String?),
      showResult: showResult ?? this.showResult,
      resultCopied: resultCopied ?? this.resultCopied,
      recentCopied: recentCopied ?? this.recentCopied,
      histFilter: histFilter ?? this.histFilter,
      historySearch: historySearch ?? this.historySearch,
      histCopied: histCopied ?? this.histCopied,
      history: history ?? this.history,
      autoSave: autoSave ?? this.autoSave,
      smartEnhance: smartEnhance ?? this.smartEnhance,
      darkMode: darkMode ?? this.darkMode,
      outputLanguage: outputLanguage ?? this.outputLanguage,
    );
  }

  List<HistoryEntryModel> get filteredHistory {
    final query = historySearch.trim().toLowerCase();
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfWeek = startOfToday.subtract(Duration(days: now.weekday - 1));

    return history.where((entry) {
      if (query.isNotEmpty && !entry.prompt.toLowerCase().contains(query)) return false;
      if (histFilter == 1) return !entry.createdAt.isBefore(startOfToday);
      if (histFilter == 2) return !entry.createdAt.isBefore(startOfWeek);
      return true;
    }).toList();
  }

  List<({String label, List<HistoryEntryModel> items})> get groupedHistory {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final todayItems = <HistoryEntryModel>[];
    final yesterdayItems = <HistoryEntryModel>[];
    final earlierItems = <HistoryEntryModel>[];

    for (final entry in filteredHistory) {
      final day = DateTime(entry.createdAt.year, entry.createdAt.month, entry.createdAt.day);
      if (day == today) {
        todayItems.add(entry);
      } else if (day == yesterday) {
        yesterdayItems.add(entry);
      } else {
        earlierItems.add(entry);
      }
    }

    return [
      if (todayItems.isNotEmpty) (label: 'TODAY', items: todayItems),
      if (yesterdayItems.isNotEmpty) (label: 'YESTERDAY', items: yesterdayItems),
      if (earlierItems.isNotEmpty) (label: 'EARLIER', items: earlierItems),
    ];
  }
}
