import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app_template/src/core/components/pop_up/slide_up_pop_up.dart';
import 'package:flutter_app_template/src/core/extensions/context_extension.dart';
import 'package:flutter_app_template/src/core/services/locator/locator.dart';
import 'package:flutter_app_template/src/features/image_to_prompt/create/presentation/views/create_view.dart';
import 'package:flutter_app_template/src/features/image_to_prompt/history/presentation/widgets/delete_confirm_sheet.dart';
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
  }

  @override
  void dispose() {
    _entrance.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _useEntry(HistoryEntryModel entry) {
    cubit.useHistoryEntry(entry.id);
    context.go(CreateView.routeName);
  }

  Future<void> _deleteEntry(HistoryEntryModel entry, PromptColors c) async {
    final confirmed = await SlideUpPopUp.show<bool>(
      context: context,
      backgroundColor: c.card,
      borderRadius: BorderRadius.circular(24),
      child: DeleteConfirmSheet(c: c),
    );
    if (confirmed != true) return;
    cubit.deleteHistoryEntry(entry.id);
    showTopAlert('Removed from history');
    if (mounted) context.pop();
  }

  void _copyPrompt(String prompt) {
    Clipboard.setData(ClipboardData(text: prompt));
    setState(() => _copied = true);
    showTopAlert('Copied to clipboard');
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  void _openImagePreview(Uint8List bytes) {
    Navigator.of(context).push(PageRouteBuilder(
      opaque: false,
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, animation, secondaryAnimation) {
        return FadeTransition(
          opacity: animation,
          child: _ImagePreviewView(imageBytes: bytes),
        );
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ImageToPromptCubit, ImageToPromptState>(
      bloc: cubit,
      builder: (context, state) {
        final c = PromptColors(state.darkMode);
        // Re-resolve against live state so a delete elsewhere is reflected
        // immediately; fall back to the entry passed via `extra` if it's gone.
        final entry = state.history.firstWhere(
          (e) => e.id == widget.entry.id,
          orElse: () => widget.entry,
        );
        final imageBytes = entry.imageBytes;
        final imageHeight = MediaQuery.of(context).size.height * 0.48;

        return Scaffold(
          backgroundColor: c.page,
          body: Column(
            children: [
              _DetailHeader(
                c: c,
                onBack: () => context.pop(),
              ),
              Expanded(
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                  SliverToBoxAdapter(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: imageBytes != null && imageBytes.isNotEmpty
                          ? () => _openImagePreview(imageBytes)
                          : null,
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
                                    child: SelectableText(
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
                                      label: 'Use Image',
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
                                            onTap: () => _deleteEntry(entry, c),
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
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ImagePreviewView extends StatefulWidget {
  final Uint8List imageBytes;

  const _ImagePreviewView({required this.imageBytes});

  @override
  State<_ImagePreviewView> createState() => _ImagePreviewViewState();
}

class _ImagePreviewViewState extends State<_ImagePreviewView> with SingleTickerProviderStateMixin {
  static const _dismissThreshold = 120.0;
  static const _dismissVelocity = 800.0;
  static const _maxDragForFade = 280.0;
  static const _doubleTapZoomScale = 2.75;

  final _transformController = TransformationController();
  late final AnimationController _dragAnim;
  Animation<Offset>? _dragOffsetAnim;

  late final AnimationController _zoomAnim;
  Animation<Matrix4>? _zoomTween;

  Offset _dragOffset = Offset.zero;
  double _zoomScale = 1;
  bool _dragging = false;

  bool get _canDismissDrag => _zoomScale <= 1.02;

  @override
  void initState() {
    super.initState();
    _dragAnim = AnimationController(vsync: this)
      ..addListener(() {
        final anim = _dragOffsetAnim;
        if (anim != null) setState(() => _dragOffset = anim.value);
      });
    _zoomAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 260))
      ..addListener(() {
        final tween = _zoomTween;
        if (tween != null) _transformController.value = tween.value;
      });
    _transformController.addListener(() {
      final scale = _transformController.value.getMaxScaleOnAxis();
      if ((scale - _zoomScale).abs() > 0.01) setState(() => _zoomScale = scale);
    });
  }

  @override
  void dispose() {
    _dragAnim.dispose();
    _zoomAnim.dispose();
    _transformController.dispose();
    super.dispose();
  }

  void _animateZoomTo(Matrix4 target) {
    _zoomTween = Matrix4Tween(begin: _transformController.value, end: target)
        .animate(CurvedAnimation(parent: _zoomAnim, curve: Curves.easeOutCubic));
    _zoomAnim.forward(from: 0);
  }

  void _onVerticalDragStart(DragStartDetails details) {
    _dragAnim.stop();
    _dragging = true;
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (!_dragging) return;
    setState(() => _dragOffset += details.delta);
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (!_dragging) return;
    _dragging = false;
    final velocity = details.primaryVelocity ?? 0;
    final shouldDismiss = _dragOffset.dy.abs() > _dismissThreshold || velocity.abs() > _dismissVelocity;
    if (shouldDismiss) {
      _flingAway();
    } else {
      _springBack();
    }
  }

  void _flingAway() {
    final screenHeight = MediaQuery.of(context).size.height;
    final direction = _dragOffset.dy >= 0 ? 1.0 : -1.0;
    _dragOffsetAnim = Tween<Offset>(begin: _dragOffset, end: Offset(_dragOffset.dx, direction * screenHeight))
        .animate(CurvedAnimation(parent: _dragAnim, curve: Curves.easeOut));
    _dragAnim.duration = const Duration(milliseconds: 200);
    _dragAnim.forward(from: 0).whenComplete(() {
      if (mounted) Navigator.of(context).pop();
    });
  }

  void _springBack() {
    _dragOffsetAnim = Tween<Offset>(begin: _dragOffset, end: Offset.zero)
        .animate(CurvedAnimation(parent: _dragAnim, curve: Curves.easeOutCubic));
    _dragAnim.duration = const Duration(milliseconds: 260);
    _dragAnim.forward(from: 0);
  }

  TapDownDetails? _doubleTapDetails;

  void _onDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
  }

  void _onDoubleTap() {
    final details = _doubleTapDetails;
    if (details == null) return;
    if (_zoomScale > 1.01) {
      _animateZoomTo(Matrix4.identity());
      return;
    }
    final position = details.localPosition;
    const scale = _doubleTapZoomScale;
    _animateZoomTo(
      Matrix4.identity()
        ..translate(-position.dx * (scale - 1), -position.dy * (scale - 1))
        ..scale(scale),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dragDistance = _dragOffset.dy.abs();
    final progress = (dragDistance / _maxDragForFade).clamp(0.0, 1.0);
    final imageScale = 1 - progress * 0.35;
    final backgroundOpacity = 1 - progress;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: backgroundOpacity)),
          ),
          Positioned.fill(
            child: GestureDetector(
              onVerticalDragStart: _canDismissDrag ? _onVerticalDragStart : null,
              onVerticalDragUpdate: _canDismissDrag ? _onVerticalDragUpdate : null,
              onVerticalDragEnd: _canDismissDrag ? _onVerticalDragEnd : null,
              onDoubleTapDown: _onDoubleTapDown,
              onDoubleTap: _onDoubleTap,
              child: Transform.translate(
                offset: _dragOffset,
                child: Transform.scale(
                  scale: imageScale,
                  child: InteractiveViewer(
                    transformationController: _transformController,
                    panEnabled: !_canDismissDrag,
                    minScale: 1,
                    maxScale: 5,
                    child: Center(
                      child: Image.memory(widget.imageBytes, fit: BoxFit.contain),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Align(
                alignment: Alignment.topLeft,
                child: _PreviewIconButton(
                  icon: Icons.close,
                  opacity: backgroundOpacity,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewIconButton extends StatelessWidget {
  final IconData icon;
  final double opacity;
  final VoidCallback onTap;

  const _PreviewIconButton({required this.icon, required this.opacity, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.black54.withValues(alpha: opacity),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
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

class _PromptGenWordmark extends StatelessWidget {
  final PromptColors c;
  const _PromptGenWordmark({required this.c});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.auto_awesome, color: PromptColors.primary, size: 18),
        const SizedBox(width: 6),
        Text(
          'PromptGen',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: c.accentText,
          ),
        ),
      ],
    );
  }
}

class _DetailHeader extends StatelessWidget {
  final PromptColors c;
  final VoidCallback onBack;

  const _DetailHeader({
    required this.c,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: c.dark
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [const Color(0xFF7C3AED).withValues(alpha: 0.18), Colors.transparent],
              )
            : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF0EBFB), Color(0xFFF8F7F3)],
              ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
          child: SizedBox(
            height: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _HeaderIconButton(icon: Icons.arrow_back, c: c, onTap: onBack),
                _PromptGenWordmark(c: c),
                const SizedBox(width: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatefulWidget {
  final IconData icon;
  final PromptColors c;
  final VoidCallback onTap;

  const _HeaderIconButton({required this.icon, required this.c, required this.onTap});

  @override
  State<_HeaderIconButton> createState() => _HeaderIconButtonState();
}

class _HeaderIconButtonState extends State<_HeaderIconButton> {
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
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: widget.c.iconBox,
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
            child: Icon(
              widget.icon,
              key: ValueKey(widget.icon),
              color: widget.c.accentText,
              size: 18,
            ),
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
