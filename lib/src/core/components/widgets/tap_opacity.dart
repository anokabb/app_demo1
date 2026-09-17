import 'package:flutter/material.dart';

/// A tap target that dims its child's opacity on press instead of showing
/// Flutter's default `InkWell`/`ListTile` ripple — the ripple's splash/highlight
/// colors don't adapt to this app's custom dark/light theme. Drop-in replacement
/// that doesn't alter the child's layout, font, or text style.
class TapOpacity extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const TapOpacity({super.key, required this.child, this.onTap});

  @override
  State<TapOpacity> createState() => _TapOpacityState();
}

class _TapOpacityState extends State<TapOpacity> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null ? null : (_) => setState(() => _pressed = true),
      onTapCancel: widget.onTap == null ? null : () => setState(() => _pressed = false),
      onTapUp: widget.onTap == null ? null : (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedOpacity(
        opacity: _pressed ? 0.5 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
