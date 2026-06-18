import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app_template/src/core/services/locator/locator.dart';
import 'package:flutter_app_template/src/features/image_to_prompt/create/presentation/views/create_view.dart';
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

  static const _filters = ['All', 'Today', 'This Week'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ImageToPromptCubit, ImageToPromptState>(
      bloc: cubit,
      builder: (context, state) {
        final c = PromptColors(state.darkMode);
        final groups = state.groupedHistory;

        return Scaffold(
          backgroundColor: c.page,
          body: ListView(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 130),
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
              const SizedBox(height: 22),

              // Search
              Container(
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
                  ],
                ),
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
                      return Padding(
                        key: ValueKey(entry.id),
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Dismissible(
                          key: ValueKey('dismiss-${entry.id}'),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) => cubit.deleteHistoryEntry(entry.id),
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
                              cubit.useHistoryEntry(entry.id);
                              context.go(CreateView.routeName);
                            },
                            child: _HistoryCard(
                              entry: entry,
                              c: c,
                              copied: state.histCopied == globalIndex,
                              onCopy: () {
                                Clipboard.setData(ClipboardData(text: entry.prompt));
                                cubit.copyHistory(globalIndex);
                              },
                              onToggleSaved: () => cubit.toggleHistorySaved(entry.id),
                            ),
                          ),
                        ),
                      );
                    }),
                  ];
                }),
            ],
          ),
        );
      },
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
                Row(
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
                    const SizedBox(width: 8),
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
