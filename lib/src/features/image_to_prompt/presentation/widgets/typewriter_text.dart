import 'dart:async';

import 'package:flutter/material.dart';

/// Reveals [text] one character at a time, restarting whenever the text
/// value changes — used for the generated prompt result so it reads like
/// it's being typed out rather than popping in all at once.
class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration charDelay;

  const TypewriterText({
    super.key,
    required this.text,
    this.style,
    this.charDelay = const Duration(milliseconds: 12),
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  Timer? _timer;
  int _visibleChars = 0;

  @override
  void initState() {
    super.initState();
    _restart();
  }

  @override
  void didUpdateWidget(TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) _restart();
  }

  void _restart() {
    _timer?.cancel();
    _visibleChars = 0;
    if (widget.text.isEmpty) return;
    _timer = Timer.periodic(widget.charDelay, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _visibleChars++);
      if (_visibleChars >= widget.text.length) timer.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visible = widget.text.substring(0, _visibleChars.clamp(0, widget.text.length));
    return Text(visible, style: widget.style);
  }
}
