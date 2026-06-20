import 'dart:ui';

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

class _HistoryDetailViewState extends State<HistoryDetailView> with TickerProviderStateMixin {
  final cubit = locator<ImageToPromptCubit>();
  final _scrollController = ScrollController();

  late final AnimationController _entrance;
  late final Animation<double> _heroScale;
  late final Animation<double> _heroFade;
  late final Animation<double> _pill1;
  late final Animation<double> _pill2;
  late final Animation<double> _pill3;
  late final Animation<Offset> _cardSlide;
  late final Animation<double> _cardFade;
  late final Animation<double> _actionsFade;

  late final AnimationController _bookmarkPop;
  late final Animation<double> _bookmarkScale;

  double _headerOpacity = 0;
  bool _copied = false;

  @override
  void initState() {
    super.initState();

    _entrance = AnimationController(duration: const Duration(milliseconds: 900), vsync: this);
    _heroScale = Tween<double>(begin: 1.12, end: 1).animate(
      CurvedAnimation(parent: _entrance, curve: const Interval(0, 0.7, curve: Curves.easeOutCubic)),
    );
    _heroFade = CurvedAnimation(parent: _entrance, curve: const Interval(0, 0.4, curve: Curves.easeOut));
    _pill1 = CurvedAnimation(parent: _entrance, curve: const Interval(0.25, 0.65, curve: Curves.easeOutCubic));
    _pill2 = CurvedAnimation(parent: _entrance, curve: const Interval(0.32, 0.72, curve: Curves.easeOutCubic));
    _pill3 = CurvedAnimation(parent: _entrance, curve: const Interval(0.39, 0.79, curve: Curves.easeOutCubic));
    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
      CurvedAnimation(parent: _entrance, curve: const Interval(0.35, 0.85, curve: Curves.easeOutCubic)),
    );
    _cardFade = CurvedAnimation(parent: _entrance, curve: const Interval(0.35, 0.85, curve: Curves.easeOut));
    _actionsFade = CurvedAnimation(parent: _entrance, curve: const Interval(0.55, 1, curve: Curves.easeOut));
    _entrance.forward();

    _bookmarkPop = AnimationController(duration: const Duration(milliseconds: 360), vsync: this);
    _bookmarkScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35).chain(CurveTween(curve: Curves.easeOut)), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 60),
    ]).animate(_bookmarkPop);

    _scrollController.addListener(() {
      final next = (_scrollController.offset / 160).clamp(0, 1).toDouble();
      if (next != _headerOpacity) setState(() => _headerOpacity = next);
    });
  }

  @override
  void dispose() {
    _entrance.dispose();
    _bookmarkPop.dispose();
    _scrollController.dispose();
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

  void _toggleSaved(HistoryEntryModel entry) {
    cubit.toggleHistorySaved(entry.id);
    _bookmarkPop.forward(from: 0);
  }

  void _copyPrompt(String prompt) {
    Clipboard.setData(ClipboardData(text: prompt));
    setState(() => _copied = true);
    showTopAlert('Copied to clipboard');
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _copied = false);
    });
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
        final imageHeight = MediaQuery.of(context).size.height * 0.48;

        return Scaffold(
          backgroundColor: c.page,
          body: Stack(
            children: [
              CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverToBoxAdapter(
                    child: ClipRect(
                      child: Stack(
                        children: [
                          AnimatedBuilder(
                            animation: Listenable.merge([_entrance, _scrollController]),
                            builder: (context, _) {
                              final parallax = _scrollController.hasClients ? _scrollController.offset * 0.3 : 0.0;
                              return Opacity(
                                opacity: _heroFade.value,
                                child: Transform.translate(
                                  offset: Offset(0, parallax),
                                  child: Transform.scale(
                                    scale: _heroScale.value,
                                    child: SizedBox(
                                      height: imageHeight,
                                      width: double.infinity,
                                      child: imageBytes != null && imageBytes.isNotEmpty
                                          ? Image.memory(imageBytes, fit: BoxFit.cover, width: double.infinity)
                                          : Container(
                                              color: c.field,
                                              child: Icon(Icons.image_outlined, size: 56, color: c.muted),
                                            ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              height: 200,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.black.withValues(alpha: 0), Colors.black.withValues(alpha: 0.75)],
                                ),
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
                                _StaggerPop(
                                  animation: _pill1,
                                  child: _Pill(icon: Icons.auto_awesome, label: entry.tier.label, accent: true),
                                ),
                                _StaggerPop(
                                  animation: _pill2,
                                  child: _Pill(icon: Icons.language, label: entry.outputLanguage),
                                ),
                                _StaggerPop(
                                  animation: _pill3,
                                  child: _Pill(icon: Icons.schedule, label: _fullDate(entry.createdAt)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(22, 28, 22, 140),
                    sliver: SliverToBoxAdapter(
                      child: SlideTransition(
                        position: _cardSlide,
                        child: FadeTransition(
                          opacity: _cardFade,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 3,
                                    decoration: BoxDecoration(
                                      gradient: PromptColors.accentGradient,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'GENERATED PROMPT',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.92, color: c.muted),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Positioned(
                                    top: -14,
                                    left: -6,
                                    child: Icon(Icons.format_quote, size: 40, color: c.accentText.withValues(alpha: 0.25)),
                                  ),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.fromLTRB(22, 24, 20, 22),
                                    decoration: BoxDecoration(
                                      color: c.card,
                                      border: Border.all(color: c.line, width: 1.5),
                                      borderRadius: BorderRadius.circular(22),
                                      boxShadow: [PromptColors.cardShadow],
                                    ),
                                    child: Text(
                                      entry.prompt,
                                      style: TextStyle(fontSize: 16, height: 1.65, color: c.ink),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              FadeTransition(
                                opacity: _actionsFade,
                                child: Column(
                                  children: [
                                    _ActionButton(
                                      icon: Icons.auto_awesome_mosaic_outlined,
                                      label: 'Use Prompt',
                                      filled: true,
                                      c: c,
                                      onTap: () => _useEntry(entry),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _ActionButton(
                                            icon: _copied ? Icons.check_circle : Icons.content_copy,
                                            label: _copied ? 'Copied!' : 'Copy',
                                            c: c,
                                            onTap: () => _copyPrompt(entry.prompt),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _ActionButton(
                                            icon: Icons.delete_outline,
                                            label: 'Delete',
                                            danger: true,
                                            c: c,
                                            onTap: () => _deleteEntry(entry),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                    child: SizedBox(
                      height: 48,
                      child: Stack(
                        children: [
                          if (_headerOpacity > 0)
                            Positioned.fill(
                              child: Opacity(
                                opacity: _headerOpacity,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                                    child: Container(color: c.card.withValues(alpha: 0.85)),
                                  ),
                                ),
                              ),
                            ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _RoundIconButton(icon: Icons.arrow_back, onTap: () => context.pop()),
                              AnimatedBuilder(
                                animation: _bookmarkScale,
                                builder: (context, _) => Transform.scale(
                                  scale: _bookmarkScale.value,
                                  child: _RoundIconButton(
                                    icon: entry.isSaved ? Icons.bookmark : Icons.bookmark_outline,
                                    filled: entry.isSaved,
                                    onTap: () => _toggleSaved(entry),
                                  ),
                                ),
                              ),
                            ],
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

class _StaggerPop extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const _StaggerPop({required this.animation, required this.child});

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(animation),
        child: child,
      ),
    );
  }
}

class _RoundIconButton extends StatefulWidget {
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  const _RoundIconButton({required this.icon, required this.onTap, this.filled = false});

  @override
  State<_RoundIconButton> createState() => _RoundIconButtonState();
}

class _RoundIconButtonState extends State<_RoundIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.88 : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: widget.filled ? const Color(0xFF8B3DFF) : Colors.black.withValues(alpha: 0.4),
            shape: BoxShape.circle,
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            transitionBuilder: (child, anim) => ScaleTransition(
              scale: anim,
              child: RotationTransition(
                turns: Tween<double>(begin: 0.5, end: 1).animate(anim),
                child: child,
              ),
            ),
            child: Icon(widget.icon, key: ValueKey(widget.icon), color: Colors.white, size: 19),
          ),
        ),
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

class _ActionButton extends StatefulWidget {
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
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> with SingleTickerProviderStateMixin {
  bool _pressed = false;
  AnimationController? _glow;

  @override
  void initState() {
    super.initState();
    if (widget.filled) {
      _glow = AnimationController(duration: const Duration(milliseconds: 1600), vsync: this)..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _glow?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fg = widget.danger ? const Color(0xFFD14343) : (widget.filled ? Colors.white : widget.c.accentText);
    final glow = _glow ?? const AlwaysStoppedAnimation<double>(0);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedBuilder(
          animation: glow,
          builder: (context, _) {
            final borderColor = widget.danger
                ? const Color(0xFFD14343).withValues(alpha: 0.22)
                : widget.c.accentText.withValues(alpha: 0.16);
            return Container(
              height: widget.filled ? 58 : 52,
              decoration: BoxDecoration(
                gradient: widget.filled ? PromptColors.accentGradient : null,
                color: widget.filled ? null : (widget.danger ? const Color(0xFFD14343).withValues(alpha: 0.07) : widget.c.accentSoft),
                border: widget.filled ? null : Border.all(color: borderColor, width: 1.3),
                borderRadius: BorderRadius.circular(widget.filled ? 18 : 15),
                boxShadow: widget.filled
                    ? [
                        BoxShadow(
                          color: const Color(0xFF8B3DFF).withValues(alpha: 0.24 + 0.18 * glow.value),
                          blurRadius: 16 + 10 * glow.value,
                          spreadRadius: 1,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                    child: Icon(widget.icon, key: ValueKey(widget.icon), color: fg, size: widget.filled ? 19 : 17),
                  ),
                  const SizedBox(width: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      widget.label,
                      key: ValueKey(widget.label),
                      style: TextStyle(
                        fontSize: widget.filled ? 15 : 13.5,
                        fontWeight: FontWeight.w700,
                        color: fg,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
