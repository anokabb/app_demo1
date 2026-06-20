import 'package:flutter/material.dart';
import 'package:flutter_app_template/src/core/components/pop_up/slide_up_pop_up.dart';
import 'package:flutter_app_template/src/features/image_to_prompt/presentation/cubit/image_to_prompt_cubit.dart';
import 'package:flutter_app_template/src/features/image_to_prompt/presentation/prompt_colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<void> showHistoryFiltersSheet({
  required BuildContext context,
  required PromptColors c,
  required ImageToPromptCubit cubit,
}) {
  return SlideUpPopUp.show<void>(
    context: context,
    backgroundColor: c.card,
    borderRadius: BorderRadius.circular(24),
    child: _HistoryFiltersSheet(c: c, cubit: cubit),
  );
}

class _HistoryFiltersSheet extends StatelessWidget {
  final PromptColors c;
  final ImageToPromptCubit cubit;

  const _HistoryFiltersSheet({required this.c, required this.cubit});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ImageToPromptCubit, ImageToPromptState>(
      bloc: cubit,
      builder: (context, state) {
        final hasActiveFilters = state.histTier != null || state.histLanguage != null;
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 14, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Filters',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: c.ink),
                      ),
                    ),
                    AnimatedOpacity(
                      opacity: hasActiveFilters ? 1 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: GestureDetector(
                        onTap: hasActiveFilters
                            ? () {
                                cubit.setHistTier(null);
                                cubit.setHistLanguage(null);
                              }
                            : null,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                          child: Text(
                            'Clear all',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.accentText),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (state.historyTiers.length > 1) ...[
                        _SectionLabel(label: 'MODEL', c: c),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _FilterChip(
                              label: 'All Models',
                              selected: state.histTier == null,
                              onTap: () => cubit.setHistTier(null),
                              c: c,
                            ),
                            ...state.historyTiers.map((tier) => _FilterChip(
                                  label: tier.label,
                                  selected: state.histTier == tier,
                                  onTap: () => cubit.setHistTier(tier),
                                  c: c,
                                )),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                      if (state.historyLanguages.length > 1) ...[
                        _SectionLabel(label: 'LANGUAGE', c: c),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _FilterChip(
                              label: 'All Languages',
                              selected: state.histLanguage == null,
                              onTap: () => cubit.setHistLanguage(null),
                              c: c,
                            ),
                            ...state.historyLanguages.map((lang) => _FilterChip(
                                  label: lang,
                                  selected: state.histLanguage == lang,
                                  onTap: () => cubit.setHistLanguage(lang),
                                  c: c,
                                )),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: PromptColors.accentGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Done',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final PromptColors c;

  const _SectionLabel({required this.label, required this.c});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.68,
        color: c.muted,
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final PromptColors c;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: selected ? PromptColors.accentGradient : null,
          color: selected ? null : c.field,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            height: 1,
            color: selected ? Colors.white : c.muted,
          ),
        ),
      ),
    );
  }
}
