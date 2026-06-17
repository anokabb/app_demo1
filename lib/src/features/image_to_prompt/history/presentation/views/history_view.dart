import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app_template/src/core/services/locator/locator.dart';
import 'package:flutter_app_template/src/features/image_to_prompt/presentation/cubit/image_to_prompt_cubit.dart';
import 'package:flutter_app_template/src/features/image_to_prompt/presentation/prompt_colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

  static const _groups = [
    (
      label: 'TODAY',
      items: [
        (
          text: '"Cinematic overhead shot of neon purple silk waves flowing across a dark void..."',
          model: 'VISION 4.0',
          time: '2h ago',
          gradient: LinearGradient(
            begin: Alignment(0.2, 0.2),
            colors: [Color(0xFFC9A227), Color(0xFF1D1505), Color(0xFF050302)],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        (
          text: '"Ethereal sunbeams piercing through dense ancient oak forest, golden hour..."',
          model: 'MIDJOURNEY',
          time: '5h ago',
          gradient: LinearGradient(
            colors: [Color(0xFF2F5A2A), Color(0xFF6E7A2E), Color(0xFFC9A14A)],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
      ],
    ),
    (
      label: 'YESTERDAY',
      items: [
        (
          text: '"Minimalist product shot of a ceramic mug on linen, soft daylight, muted tones..."',
          model: 'SDXL',
          time: '1d ago',
          gradient: LinearGradient(
            begin: Alignment(-0.5, -0.5),
            colors: [Color(0xFFD8D0C4), Color(0xFFB7A890)],
          ),
        ),
        (
          text: '"Macro photograph of a dewdrop on a green leaf, shallow focus, morning light..."',
          model: 'VISION 4.0',
          time: '1d ago',
          gradient: LinearGradient(
            colors: [Color(0xFF2E6B4F), Color(0xFF7FC9A0)],
          ),
        ),
      ],
    ),
  ];

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
        int idx = 0;

        return ListView(
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
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: selected ? PromptColors.accentGradient : null,
                        color: selected ? null : c.field,
                      ),
                      child: Center(
                        child: Text(
                          _filters[i],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.52,
                            color: selected ? Colors.white : c.muted,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),

            // History groups
            ..._groups.expand((group) {
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
                ...group.items.map((item) {
                  final i = idx++;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Container(
                      decoration: BoxDecoration(
                        color: c.card,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [PromptColors.cardShadow],
                      ),
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: item.gradient,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.text,
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
                                        item.model,
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
                                      item.time,
                                      style: TextStyle(fontSize: 12, color: c.muted, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: item.text));
                              cubit.copyHistory(i);
                            },
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: state.histCopied == i ? c.accentText : c.accentSoft,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.content_copy,
                                color: state.histCopied == i ? Colors.white : c.accentText,
                                size: 17,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ];
            }),
          ],
        );
      },
    );
  }
}
