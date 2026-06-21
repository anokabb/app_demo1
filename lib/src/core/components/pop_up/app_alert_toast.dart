import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app_template/src/core/routing/app_router.dart';
import 'package:flutter_app_template/src/core/services/locator/locator.dart';
import 'package:flutter_app_template/src/features/image_to_prompt/presentation/cubit/image_to_prompt_cubit.dart';

/// Unified alert/error toast UI — used for both success and error messages.
/// Adapts its colors to the app's current light/dark theme.
class AppAlertToast extends StatelessWidget {
  final String message;
  final bool isError;

  const AppAlertToast({super.key, required this.message, required this.isError});

  @override
  Widget build(BuildContext context) {
    // The image-to-prompt feature's own Settings dark-mode toggle is the only
    // dark-mode switch this app's UI exposes — the app-wide ThemeCubit is
    // never touched by it, so this toast must follow ImageToPromptCubit instead.
    final isDark = locator<ImageToPromptCubit>().state.darkMode;
    final accent = isError ? const Color(0xFFE5484D) : const Color(0xFF30A46C);
    final background = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1C1C1E);

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(18),
          border: isDark ? null : Border.all(color: const Color(0xFFE7E1F2), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.12),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(color: accent.withValues(alpha: 0.18), shape: BoxShape.circle),
              child: Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: accent, size: 17),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 13.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToastOverlayWidget extends StatefulWidget {
  final String message;
  final bool isError;
  final VoidCallback onDismissed;

  const _ToastOverlayWidget({required this.message, required this.isError, required this.onDismissed});

  @override
  State<_ToastOverlayWidget> createState() => _ToastOverlayWidgetState();
}

class _ToastOverlayWidgetState extends State<_ToastOverlayWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 260));
    _controller.forward();
    _timer = Timer(const Duration(milliseconds: 2600), _dismiss);
  }

  Future<void> _dismiss() async {
    _timer?.cancel();
    if (!mounted) return;
    await _controller.reverse();
    widget.onDismissed();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
          child: AnimatedBuilder(
            animation: curved,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, 30 * (1 - curved.value)),
                child: Opacity(opacity: curved.value.clamp(0.0, 1.0), child: child),
              );
            },
            child: GestureDetector(
              onTap: _dismiss,
              child: AppAlertToast(message: widget.message, isError: widget.isError),
            ),
          ),
        ),
      ),
    );
  }
}

OverlayEntry? _activeToastEntry;

/// Shows the unified bottom-sliding alert/error toast.
void showAppAlert(String message, {bool isError = false}) {
  final overlayState = rootNavigatorKey.currentState?.overlay;
  if (overlayState == null) return;

  _activeToastEntry?.remove();
  _activeToastEntry = null;

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => _ToastOverlayWidget(
      message: message,
      isError: isError,
      onDismissed: () {
        entry.remove();
        if (_activeToastEntry == entry) _activeToastEntry = null;
      },
    ),
  );
  _activeToastEntry = entry;
  overlayState.insert(entry);
}

void showAppError(String message) => showAppAlert(message, isError: true);
