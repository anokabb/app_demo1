import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app_template/src/core/components/pop_up/slide_up_pop_up.dart';
import 'package:flutter_app_template/src/core/extensions/context_extension.dart';
import 'package:flutter_app_template/src/core/services/locator/locator.dart';
import 'package:flutter_app_template/src/features/image_to_prompt/history/presentation/views/history_detail_view.dart';
import 'package:flutter_app_template/src/features/image_to_prompt/history/presentation/widgets/delete_confirm_sheet.dart';
import 'package:flutter_app_template/src/features/image_to_prompt/history/presentation/widgets/history_filters_sheet.dart';
import 'package:flutter_app_template/src/features/image_to_prompt/infrastructure/image_prompt_repo.dart';
import 'package:flutter_app_template/src/features/image_to_prompt/models/history_entry_model.dart';
import 'package:flutter_app_template/src/features/image_to_prompt/presentation/cubit/image_to_prompt_cubit.dart';
import 'package:flutter_app_template/src/features/image_to_prompt/presentation/prompt_colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

String _relativeTime(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${time.month}/${time.day}/${time.year}';
}

class HistoryView extends StatefulWidget {
  static const routeName = '/image-to-prompt/history';
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  final cubit = locator<ImageToPromptCubit>();
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  static const _filters = ['All', 'Today', 'This Week'];

  bool _selectionMode = false;
  final Set<String> _selectedIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _enterSelectionMode(String id) {
    setState(() {
      _selectionMode = true;
      _selectedIds.add(id);
    });
  }

  void _toggleSelected(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  Future<bool> _confirmDeleteSingle(PromptColors c) async {
    final confirmed = await SlideUpPopUp.show<bool>(
      context: context,
      backgroundColor: c.card,
      borderRadius: BorderRadius.circular(24),
      child: DeleteConfirmSheet(c: c),
    );
    return confirmed == true;
  }

  Future<void> _confirmBulkDelete(PromptColors c) async {
    final count = _selectedIds.length;
    final confirmed = await SlideUpPopUp.show<bool>(
      context: context,
      backgroundColor: c.card,
      borderRadius: BorderRadius.circular(24),
      child: DeleteConfirmSheet(
        c: c,
        title: 'Remove $count item${count == 1 ? '' : 's'}?',
        message: 'These prompts and their images will be permanently removed from your history.',
        confirmLabel: 'Delete',
      ),
    );
    if (confirmed != true) return;
    cubit.deleteHistoryEntries(_selectedIds);
    showTopAlert('Removed $count item${count == 1 ? '' : 's'}');
    _exitSelectionMode();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ImageToPromptCubit, ImageToPromptState>(
      bloc: cubit,
      listenWhen: (prev, curr) => curr.scrollToTopTab == 1 && curr.scrollToTopTick != prev.scrollToTopTick,
      listener: (context, state) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(0, duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
        }
      },
      builder: (context, state) {
        final c = PromptColors(state.darkMode);
        final groups = state.groupedHistory;

        return Scaffold(
          backgroundColor: c.page,
          body: Stack(
            children: [
              ListView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 130),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'History',
                          style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.33,
                            height: 1.04,
                            color: c.ink,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'All your generated prompts in one place.',
                          style: TextStyle(fontSize: 16, height: 1.45, color: c.muted),
                        ),
                      ],
                    ),
                  ),
                  if (groups.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: GestureDetector(
                        onTap: () {
                          if (_selectionMode) {
                            _exitSelectionMode();
                          } else {
                            setState(() => _selectionMode = true);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                          decoration: BoxDecoration(color: c.field, borderRadius: BorderRadius.circular(14)),
                          child: Text(
                            _selectionMode ? 'Cancel' : 'Select',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _selectionMode ? c.muted : c.accentText,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 22),

              // Search
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 54,
                      decoration: BoxDecoration(
                        color: c.field,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: c.muted, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: cubit.setHistorySearch,
                              style: TextStyle(fontSize: 15, color: c.ink),
                              decoration: InputDecoration(
                                hintText: 'Search prompts...',
                                hintStyle: TextStyle(color: c.muted, fontSize: 15),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          ValueListenableBuilder<TextEditingValue>(
                            valueListenable: _searchController,
                            builder: (context, value, _) {
                              final hasText = value.text.isNotEmpty;
                              return IgnorePointer(
                                ignoring: !hasText,
                                child: AnimatedOpacity(
                                  opacity: hasText ? 1 : 0,
                                  duration: const Duration(milliseconds: 160),
                                  child: AnimatedScale(
                                    scale: hasText ? 1 : 0.6,
                                    duration: const Duration(milliseconds: 160),
                                    curve: Curves.easeOutBack,
                                    child: GestureDetector(
                                      onTap: () {
                                        _searchController.clear();
                                        cubit.setHistorySearch('');
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 6),
                                        child: Icon(Icons.cancel, color: c.muted, size: 18),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (state.historyTiers.length > 1 || state.historyLanguages.length > 1) ...[
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => showHistoryFiltersSheet(context: context, c: c, cubit: cubit),
                      child: Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: c.field,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              Icons.tune,
                              color: (state.histTier != null || state.histLanguage != null) ? c.accentText : c.muted,
                              size: 22,
                            ),
                            if (state.histTier != null || state.histLanguage != null)
                              Positioned(
                                top: 9,
                                right: 9,
                                child: Container(
                                  width: 9,
                                  height: 9,
                                  decoration: BoxDecoration(
                                    color: c.accentText,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: c.field, width: 2),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 18),

              // Filter chips
              Row(
                children: List.generate(_filters.length, (i) {
                  final selected = state.histFilter == i;
                  return Padding(
                    padding: EdgeInsets.only(right: i < _filters.length - 1 ? 10 : 0),
                    child: GestureDetector(
                      onTap: () => cubit.setHistFilter(i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: selected ? PromptColors.accentGradient : null,
                          color: selected ? null : c.field,
                        ),
                        child: Text(
                          _filters[i],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.52,
                            height: 1,
                            color: selected ? Colors.white : c.muted,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 24),

              if (groups.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Column(
                    children: [
                      Icon(Icons.history, color: c.muted, size: 40),
                      const SizedBox(height: 14),
                      Text(
                        state.history.isEmpty ? 'No prompts yet.' : 'No results match your search.',
                        style: TextStyle(fontSize: 14, color: c.muted),
                      ),
                    ],
                  ),
                )
              else
                ...groups.expand((group) {
                  return [
                    Padding(
                      padding: const EdgeInsets.only(left: 2, bottom: 14),
                      child: Text(
                        group.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.68,
                          color: c.muted,
                        ),
                      ),
                    ),
                    ...group.items.map((entry) {
                      final globalIndex = state.filteredHistory.indexOf(entry);
                      final selected = _selectedIds.contains(entry.id);
                      return Padding(
                        key: ValueKey(entry.id),
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Dismissible(
                          key: ValueKey('dismiss-${entry.id}'),
                          direction: _selectionMode ? DismissDirection.none : DismissDirection.endToStart,
                          confirmDismiss: (_) => _confirmDeleteSingle(c),
                          onDismissed: (_) {
                            cubit.deleteHistoryEntry(entry.id);
                            showTopAlert('Removed from history');
                          },
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 22),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD14343),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(Icons.delete_outline, color: Colors.white),
                          ),
                          child: GestureDetector(
                            onTap: () {
                              if (_selectionMode) {
                                _toggleSelected(entry.id);
                              } else {
                                context.push(HistoryDetailView.routeName, extra: entry);
                              }
                            },
                            onLongPress: _selectionMode ? null : () => _enterSelectionMode(entry.id),
                            child: Stack(
                              children: [
                                _HistoryCard(
                                  entry: entry,
                                  c: c,
                                  copied: state.histCopied == globalIndex,
                                  onCopy: () {
                                    Clipboard.setData(ClipboardData(text: entry.prompt));
                                    cubit.copyHistory(globalIndex);
                                    showTopAlert('Copied to clipboard');
                                  },
                                  onToggleSaved: () => cubit.toggleHistorySaved(entry.id),
                                ),
                                if (_selectionMode)
                                  Positioned(
                                    top: 10,
                                    left: 10,
                                    child: _SelectionCheckbox(selected: selected, c: c),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ];
                }),
            ],
          ),
              if (_selectionMode && _selectedIds.isNotEmpty)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SafeArea(
                    child: _BulkDeleteBar(
                      count: _selectedIds.length,
                      onDelete: () => _confirmBulkDelete(c),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SelectionCheckbox extends StatelessWidget {
  final bool selected;
  final PromptColors c;

  const _SelectionCheckbox({required this.selected, required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? c.accentText : Colors.black.withValues(alpha: 0.35),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: selected ? const Icon(Icons.check, color: Colors.white, size: 15) : null,
    );
  }
}

class _BulkDeleteBar extends StatelessWidget {
  final int count;
  final VoidCallback onDelete;

  const _BulkDeleteBar({required this.count, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
      child: GestureDetector(
        onTap: onDelete,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFD14343),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 10)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.delete_outline, color: Colors.white, size: 19),
              const SizedBox(width: 8),
              Text(
                'Delete $count item${count == 1 ? '' : 's'}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final HistoryEntryModel entry;
  final PromptColors c;
  final bool copied;
  final VoidCallback onCopy;
  final VoidCallback onToggleSaved;

  const _HistoryCard({
    required this.entry,
    required this.c,
    required this.copied,
    required this.onCopy,
    required this.onToggleSaved,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [PromptColors.cardShadow],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              entry.imageBytes ?? Uint8List(0),
              width: 64,
              height: 64,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.prompt,
                  style: TextStyle(fontSize: 14, height: 1.4, color: c.ink),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: c.accentSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      child: Text(
                        entry.tier.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: c.accentText,
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: c.field,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.language, size: 11, color: c.muted),
                          const SizedBox(width: 4),
                          Text(
                            entry.outputLanguage,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                              color: c.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _relativeTime(entry.createdAt),
                      style: TextStyle(fontSize: 12, color: c.muted, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onToggleSaved,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                entry.isSaved ? Icons.bookmark : Icons.bookmark_outline,
                color: entry.isSaved ? c.accentText : c.muted,
                size: 19,
              ),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onCopy,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: copied ? c.accentText : c.accentSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.content_copy,
                color: copied ? Colors.white : c.accentText,
                size: 17,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
