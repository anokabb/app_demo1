import 'package:flutter/material.dart';
import 'package:flutter_app_template/src/core/extensions/context_extension.dart';
import 'package:flutter_app_template/src/core/services/locator/locator.dart';
import 'package:flutter_app_template/src/features/image_to_prompt/infrastructure/image_prompt_repo.dart';
import 'package:flutter_app_template/src/features/image_to_prompt/presentation/cubit/image_to_prompt_cubit.dart';
import 'package:flutter_app_template/src/features/image_to_prompt/presentation/prompt_colors.dart';
import 'package:flutter_app_template/src/features/image_to_prompt/presentation/widgets/language_picker_sheet.dart';
import 'package:flutter_app_template/src/features/image_to_prompt/presentation/widgets/model_tier_picker_sheet.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class SettingsView extends StatelessWidget {
  static const routeName = '/image-to-prompt/settings';
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = locator<ImageToPromptCubit>();
    return BlocBuilder<ImageToPromptCubit, ImageToPromptState>(
      bloc: cubit,
      builder: (context, state) {
        final c = PromptColors(state.darkMode);
        return Scaffold(
          backgroundColor: c.page,
          body: SafeArea(
            child: Column(
              children: [
                _SettingsHeader(c: c),
                Expanded(child: _SettingsBody(state: state, cubit: cubit, c: c)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  final PromptColors c;
  const _SettingsHeader({required this.c});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3C1E78).withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(Icons.chevron_left, color: c.ink, size: 22),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            'Settings',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.48,
              color: c.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsBody extends StatelessWidget {
  final ImageToPromptState state;
  final ImageToPromptCubit cubit;
  final PromptColors c;
  const _SettingsBody({required this.state, required this.cubit, required this.c});

  static const _aboutRows = [
    ('Rate the app', ''),
    ('Terms of Service', ''),
    ('App version', '2.4.0'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 40),
      children: [
        _SectionLabel(label: 'PREFERENCES', c: c),
        Container(
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [PromptColors.cardShadow],
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            children: [
              _ToggleRow(
                icon: Icons.save_outlined,
                title: 'Auto-save prompts',
                subtitle: 'Keep every result in history',
                value: state.autoSave,
                onToggle: cubit.toggleAutoSave,
                c: c,
                isFirst: true,
              ),
              _ToggleRow(
                icon: Icons.auto_awesome_outlined,
                title: 'Smart enhance',
                subtitle: 'Refine prompts automatically',
                value: state.smartEnhance,
                onToggle: cubit.toggleSmartEnhance,
                c: c,
              ),
              _ToggleRow(
                icon: Icons.dark_mode_outlined,
                title: 'Dark mode',
                subtitle: 'Use a dark color theme',
                value: state.darkMode,
                onToggle: cubit.toggleDarkMode,
                c: c,
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        _SectionLabel(label: 'DEFAULTS', c: c),
        Container(
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [PromptColors.cardShadow],
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            children: [
              _SettingsRow(
                icon: Icons.auto_awesome_outlined,
                title: 'Default model',
                trailing: state.selectedModel.label,
                c: c,
                isFirst: true,
                onTap: () async {
                  final tier = await showModelTierPickerSheet(context: context, c: c, current: state.selectedModel);
                  if (tier != null) cubit.setDefaultModel(tier);
                },
              ),
              _SettingsRow(
                icon: Icons.language,
                title: 'Output language',
                trailing: state.outputLanguage,
                c: c,
                onTap: () async {
                  final lang = await showLanguagePickerSheet(context: context, c: c, current: state.outputLanguage);
                  if (lang != null) cubit.setOutputLanguage(lang);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        _SectionLabel(label: 'ALERTS', c: c),
        Container(
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [PromptColors.cardShadow],
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            children: [
              _SettingsRow(
                icon: Icons.check_circle_outline,
                title: 'Show sample alert',
                trailing: '',
                c: c,
                isFirst: true,
                onTap: () => showTopAlert('This is a sample alert.'),
              ),
              _SettingsRow(
                icon: Icons.error_outline,
                title: 'Show sample error',
                trailing: '',
                c: c,
                onTap: () => showTopError('This is a sample error.'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        _SectionLabel(label: 'ABOUT', c: c),
        Container(
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [PromptColors.cardShadow],
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            children: List.generate(_aboutRows.length, (i) {
              final row = _aboutRows[i];
              return Column(
                children: [
                  if (i > 0) Divider(color: c.line, thickness: 1, height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            row.$1,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: c.ink,
                            ),
                          ),
                        ),
                        if (row.$2.isNotEmpty)
                          Text(
                            row.$2,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: c.muted),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Text(
            'PromptGen v2.4.0',
            style: TextStyle(fontSize: 12, color: c.muted.withValues(alpha: 0.7)),
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final PromptColors c;
  const _SectionLabel({required this.label, required this.c});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 12),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.68,
          color: c.muted,
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final VoidCallback onToggle;
  final PromptColors c;
  final bool isFirst;

  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onToggle,
    required this.c,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!isFirst) Divider(color: c.line, thickness: 1, height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: c.iconBox,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: c.accentText, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.ink)),
                    const SizedBox(height: 1),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: c.muted)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: onToggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 50,
                  height: 30,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    gradient: value ? PromptColors.accentGradient : null,
                    color: value ? null : c.trackOff,
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 200),
                    alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFCFAFF),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String trailing;
  final PromptColors c;
  final bool isFirst;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.trailing,
    required this.c,
    this.isFirst = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!isFirst) Divider(color: c.line, thickness: 1, height: 1),
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: c.iconBox,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, color: c.accentText, size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.ink)),
                ),
                Text(trailing, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.muted)),
                const SizedBox(width: 6),
                Icon(Icons.chevron_right, color: c.line, size: 17),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
