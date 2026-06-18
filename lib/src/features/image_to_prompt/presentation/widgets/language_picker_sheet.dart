import 'package:flutter/material.dart';
import 'package:flutter_app_template/src/features/image_to_prompt/presentation/prompt_colors.dart';

const kPromptLanguages = [
  'English',
  'Spanish',
  'French',
  'German',
  'Italian',
  'Portuguese',
  'Arabic',
  'Japanese',
  'Korean',
  'Chinese (Simplified)',
  'Hindi',
];

Future<String?> showLanguagePickerSheet({
  required BuildContext context,
  required PromptColors c,
  required String current,
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => _LanguagePickerSheet(c: c, current: current),
  );
}

class _LanguagePickerSheet extends StatelessWidget {
  final PromptColors c;
  final String current;
  const _LanguagePickerSheet({required this.c, required this.current});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Output Language',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: c.ink),
                ),
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                itemCount: kPromptLanguages.length,
                separatorBuilder: (_, __) => Divider(color: c.line, height: 1),
                itemBuilder: (context, index) {
                  final lang = kPromptLanguages[index];
                  final selected = lang == current;
                  return ListTile(
                    onTap: () => Navigator.of(context).pop(lang),
                    title: Text(lang, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.ink)),
                    trailing: selected ? Icon(Icons.check_circle, color: c.accentText) : null,
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
