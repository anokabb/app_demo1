import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app_template/src/core/extensions/context_extension.dart';
import 'package:flutter_app_template/src/core/services/locator/locator.dart';
import 'package:flutter_app_template/src/features/image_to_prompt/create/presentation/views/create_view.dart';
import 'package:flutter_app_template/src/features/image_to_prompt/infrastructure/image_prompt_repo.dart';
import 'package:flutter_app_template/src/features/image_to_prompt/models/history_entry_model.dart';
import 'package:flutter_app_template/src/features/image_to_prompt/presentation/cubit/image_to_prompt_cubit.dart';
import 'package:flutter_app_template/src/features/image_to_prompt/presentation/prompt_colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _fullDate(DateTime time) => '${_months[time.month - 1]} ${time.day}, ${time.year}';

class HistoryDetailView extends StatefulWidget {
  static const routeName = '/image-to-prompt/history/detail';
  final HistoryEntryModel entry;

  const HistoryDetailView({super.key, required this.entry});

  @override
  State<HistoryDetailView> createState() => _HistoryDetailViewState();
}

class _HistoryDetailViewState extends State<HistoryDetailView> with SingleTickerProviderStateMixin {
  final cubit = locator<ImageToPromptCubit>();
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 650), vsync: this);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _useEntry(HistoryEntryModel entry) {
    cubit.useHistoryEntry(entry.id);
    context.go(CreateView.routeName);
  }

  void _deleteEntry(HistoryEntryModel entry) {
    cubit.deleteHistoryEntry(entry.id);
    showTopAlert('Removed from history');
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ImageToPromptCubit, ImageToPromptState>(
      bloc: cubit,
      builder: (context, state) {
        final c = PromptColors(state.darkMode);
        // Re-resolve against live state so a save/delete elsewhere is reflected
        // immediately; fall back to the entry passed via `extra` if it's gone.
        final entry = state.history.firstWhere(
          (e) => e.id == widget.entry.id,
          orElse: () => widget.entry,
        );
        final imageBytes = entry.imageBytes;
        final imageHeight = MediaQuery.of(context).size.height * 0.46;

        return Scaffold(
          backgroundColor: c.page,
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    SizedBox(
                      height: imageHeight,
                      width: double.infinity,
                      child: imageBytes != null && imageBytes.isNotEmpty
                          ? Image.memory(imageBytes, fit: BoxFit.cover, width: double.infinity)
                          : Container(
                              color: c.field,
                              child: Icon(Icons.image_outlined, size: 56, color: c.muted),
                            ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        height: 160,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.black.withValues(alpha: 0), Colors.black.withValues(alpha: 0.65)],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 14,
                      left: 18,
                      right: 18,
                      child: SafeArea(
                        bottom: false,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _RoundIconButton(icon: Icons.arrow_back, onTap: () => context.pop()),
                            _RoundIconButton(
                              icon: entry.isSaved ? Icons.bookmark : Icons.bookmark_outline,
                              filled: entry.isSaved,
                              onTap: () => cubit.toggleHistorySaved(entry.id),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 18,
                      right: 18,
                      bottom: 16,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _Pill(icon: Icons.auto_awesome, label: entry.tier.label, accent: true),
                          _Pill(icon: Icons.language, label: entry.outputLanguage),
                          _Pill(icon: Icons.schedule, label: _fullDate(entry.createdAt)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 140),
                sliver: SliverToBoxAdapter(
                  child: SlideTransition(
                    position: _slide,
                    child: FadeTransition(
                      opacity: _fade,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'GENERATED PROMPT',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.9,
                              color: c.muted,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: c.card,
                              border: Border.all(color: c.line, width: 1.5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              entry.prompt,
                              style: TextStyle(fontSize: 16, height: 1.6, color: c.ink),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: _ActionButton(
                                  icon: Icons.content_copy,
                                  label: 'Copy',
                                  c: c,
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(text: entry.prompt));
                                    showTopAlert('Copied to clipboard');
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _ActionButton(
                                  icon: Icons.auto_awesome_mosaic_outlined,
                                  label: 'Use Prompt',
                                  filled: true,
                                  c: c,
                                  onTap: () => _useEntry(entry),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _ActionButton(
                            icon: Icons.delete_outline,
                            label: 'Delete from History',
                            danger: true,
                            c: c,
                            onTap: () => _deleteEntry(entry),
                          ),
                        ],
                      ),
                    ),
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

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  const _RoundIconButton({required this.icon, required this.onTap, this.filled = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: filled ? const Color(0xFF8B3DFF) : Colors.black.withValues(alpha: 0.4),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 19),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool accent;

  const _Pill({required this.icon, required this.label, this.accent = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: accent ? const Color(0xFF8B3DFF) : Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool filled;
  final bool danger;
  final PromptColors c;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.c,
    required this.onTap,
    this.filled = false,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = danger ? const Color(0xFFD14343) : (filled ? Colors.white : c.accentText);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: filled ? PromptColors.accentGradient : null,
          color: filled ? null : (danger ? const Color(0xFFD14343).withValues(alpha: 0.08) : c.accentSoft),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: fg, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: fg),
            ),
          ],
        ),
      ),
    );
  }
}
