import 'package:flutter/material.dart';
import 'package:flutter_app_template/src/core/components/pop_up/slide_up_pop_up.dart';
import 'package:flutter_app_template/src/features/image_to_prompt/infrastructure/image_prompt_repo.dart';
import 'package:flutter_app_template/src/features/image_to_prompt/presentation/prompt_colors.dart';

Future<ImagePromptModelTier?> showModelTierPickerSheet({
  required BuildContext context,
  required PromptColors c,
  required ImagePromptModelTier current,
}) {
  return SlideUpPopUp.show<ImagePromptModelTier>(
    context: context,
    backgroundColor: c.card,
    borderRadius: BorderRadius.circular(24),
    child: _ModelTierPickerSheet(c: c, current: current),
  );
}

class _ModelTierPickerSheet extends StatelessWidget {
  final PromptColors c;
  final ImagePromptModelTier current;
  const _ModelTierPickerSheet({required this.c, required this.current});

  @override
  Widget build(BuildContext context) {
    return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Default AI Model',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: c.ink),
                ),
              ),
            ),
            ...ImagePromptModelTier.values.map((tier) {
              final selected = tier == current;
              return ListTile(
                onTap: () => Navigator.of(context).pop(tier),
                title: Text(tier.label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.ink)),
                subtitle: Text(tier.description, style: TextStyle(fontSize: 12, color: c.muted)),
                trailing: selected ? Icon(Icons.check_circle, color: c.accentText) : null,
              );
            }),
            const SizedBox(height: 12),
          ],
        );
  }
}
