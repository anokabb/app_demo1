import 'package:flutter/material.dart';
import 'package:flutter_app_template/src/features/image_to_prompt/presentation/prompt_colors.dart';

class DeleteConfirmSheet extends StatelessWidget {
  final PromptColors c;
  final String title;
  final String message;
  final String confirmLabel;

  const DeleteConfirmSheet({
    super.key,
    required this.c,
    this.title = 'Remove from history?',
    this.message = 'This prompt and its image will be permanently removed from your history.',
    this.confirmLabel = 'Delete',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFE5484D).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.delete_outline, color: Color(0xFFE5484D), size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: c.ink),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(fontSize: 14, color: c.muted, height: 1.4),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _SheetButton(
                  icon: Icons.close,
                  label: 'Cancel',
                  c: c,
                  onTap: () => Navigator.of(context).pop(false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SheetButton(
                  icon: Icons.delete_outline,
                  label: confirmLabel,
                  danger: true,
                  c: c,
                  onTap: () => Navigator.of(context).pop(true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool danger;
  final PromptColors c;
  final VoidCallback onTap;

  const _SheetButton({
    required this.icon,
    required this.label,
    required this.c,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = danger ? const Color(0xFFD14343) : c.accentText;
    final borderColor =
        danger ? const Color(0xFFD14343).withValues(alpha: 0.22) : c.accentText.withValues(alpha: 0.16);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: danger ? const Color(0xFFD14343).withValues(alpha: 0.07) : c.accentSoft,
          border: Border.all(color: borderColor, width: 1.3),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: fg, size: 17),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: fg)),
          ],
        ),
      ),
    );
  }
}
