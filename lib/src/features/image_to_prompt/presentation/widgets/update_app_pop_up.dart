import 'package:flutter/material.dart';
import 'package:flutter_app_template/src/core/extensions/context_extension.dart';
import 'package:flutter_app_template/src/features/image_to_prompt/presentation/prompt_colors.dart';

/// Styled replacement for the `upgrader` package's default alert, matched to
/// PromptGen's own gradient/card language (the generic `AppPopUp` is themed
/// for the template's blue palette, not this app's purple identity) and
/// driven by `Theme.of(context).brightness` so it tracks light/dark mode.
class UpdateAppPopUp extends StatelessWidget {
  final String title;
  final String message;
  final String? releaseNotes;
  final String updateLabel;
  final String? laterLabel;
  final VoidCallback onUpdate;

  /// Null hides the secondary action entirely — used for a forced update,
  /// where the dialog must not be dismissible.
  final VoidCallback? onLater;

  const UpdateAppPopUp({
    super.key,
    required this.title,
    required this.message,
    required this.updateLabel,
    required this.onUpdate,
    this.releaseNotes,
    this.laterLabel,
    this.onLater,
  });

  @override
  Widget build(BuildContext context) {
    final c = PromptColors(Theme.of(context).brightness == Brightness.dark);
    final notes = releaseNotes?.trim();

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      backgroundColor: c.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: PromptColors.accentGradient,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x556C28D9),
                      blurRadius: 28,
                      offset: Offset(0, 14),
                    ),
                  ],
                ),
                child: const Icon(Icons.system_update_rounded, color: Colors.white, size: 34),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: c.ink),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, height: 1.45, color: c.muted),
              ),
              if (notes != null && notes.isNotEmpty) ...[
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    context.localization.whatsNew.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: c.muted,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 140),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: c.field,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      notes,
                      style: TextStyle(fontSize: 13, height: 1.5, color: c.ink),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: GestureDetector(
                  onTap: onUpdate,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(27),
                      gradient: PromptColors.accentGradient,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6C28D9).withValues(alpha: 0.5),
                          blurRadius: 26,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.arrow_circle_up_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          updateLabel,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (onLater != null && laterLabel != null) ...[
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: onLater,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      laterLabel!,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.muted),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
