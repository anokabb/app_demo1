import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app_template/src/core/services/locator/locator.dart';
import 'package:flutter_app_template/src/features/image_to_prompt/history/presentation/views/history_view.dart';
import 'package:flutter_app_template/src/features/image_to_prompt/presentation/cubit/image_to_prompt_cubit.dart';
import 'package:flutter_app_template/src/features/image_to_prompt/presentation/prompt_colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class CreateView extends StatefulWidget {
  static const routeName = '/image-to-prompt/create';
  const CreateView({super.key});

  @override
  State<CreateView> createState() => _CreateViewState();
}

class _CreateViewState extends State<CreateView> {
  final cubit = locator<ImageToPromptCubit>();
  final _urlController = TextEditingController();

  static const _models = ['VISION 4.0', 'SDXL REFINER', 'MIDJOURNEY V6'];

  static const _recentItems = [
    (
      text: '"Cinematic overhead shot of neon purple silk waves flowing across a dark void, volumetric light..."',
      gradient: LinearGradient(
        begin: Alignment(0.2, 0.2),
        end: Alignment(1.0, 1.0),
        colors: [Color(0xFFC9A227), Color(0xFF1D1505), Color(0xFF050302)],
        stops: [0.0, 0.55, 1.0],
      ),
    ),
    (
      text: '"Ethereal sunbeams piercing through dense ancient oak forest, golden hour, misty atmosphere..."',
      gradient: LinearGradient(
        begin: Alignment(-0.4, -0.4),
        end: Alignment(1.0, 1.0),
        colors: [Color(0xFF2F5A2A), Color(0xFF6E7A2E), Color(0xFFC9A14A)],
        stops: [0.0, 0.45, 1.0],
      ),
    ),
  ];

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ImageToPromptCubit, ImageToPromptState>(
      bloc: cubit,
      builder: (context, state) {
        final c = PromptColors(state.darkMode);
        return ListView(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 130),
          children: [
            Text(
              'Image to Prompt',
              style: TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.33,
                height: 1.04,
                color: c.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Transform any visual into a precise AI description.',
              style: TextStyle(fontSize: 16, height: 1.45, color: c.muted),
            ),
            const SizedBox(height: 26),

            // Upload zone
            DottedBorder(
              borderType: BorderType.RRect,
              radius: const Radius.circular(20),
              dashPattern: const [8, 6],
              color: c.line,
              strokeWidth: 2,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.035),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 78,
                      height: 78,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: c.iconBox,
                      ),
                      child: Icon(Icons.image_outlined, color: c.accentText, size: 34),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'UPLOAD IMAGE',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.4,
                        color: c.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),

            // OR divider
            Row(
              children: [
                Expanded(child: Divider(color: c.line, thickness: 1, height: 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    'OR',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.16,
                      color: c.muted,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: c.line, thickness: 1, height: 1)),
              ],
            ),
            const SizedBox(height: 22),

            // URL input
            Container(
              height: 58,
              decoration: BoxDecoration(
                color: c.field,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _urlController,
                      style: TextStyle(fontSize: 16, color: c.ink),
                      decoration: InputDecoration(
                        hintText: 'Paste image URL...',
                        hintStyle: TextStyle(color: c.muted, fontSize: 16),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  Icon(Icons.link, color: c.muted, size: 22),
                ],
              ),
            ),
            const SizedBox(height: 34),

            // AI Model
            Text(
              'Select AI Model',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.46,
                color: c.ink,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 11,
              runSpacing: 11,
              children: List.generate(_models.length, (i) {
                final selected = state.selectedModel == i;
                return GestureDetector(
                  onTap: () => cubit.selectModel(i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: selected ? PromptColors.accentGradient : null,
                      color: selected ? null : c.field,
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF6C28D9).withValues(alpha: 0.55),
                                blurRadius: 24,
                                offset: const Offset(0, 12),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        _models[i],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.84,
                          color: selected ? Colors.white : c.muted,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 34),

            // Output language
            Text(
              'Output Language',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.46,
                color: c.ink,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 58,
                    decoration: BoxDecoration(
                      color: c.card,
                      border: Border.all(color: c.line, width: 1.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'English (US)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: c.ink,
                          ),
                        ),
                        Icon(Icons.keyboard_arrow_down, color: c.muted, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Container(
                    height: 58,
                    decoration: BoxDecoration(
                      color: c.card,
                      border: Border.all(color: c.line, width: 1.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.language, color: c.accentText, size: 20),
                        const SizedBox(width: 9),
                        Text(
                          'AUTO-DETECT',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.91,
                            color: c.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Generate button
            GestureDetector(
              onTap: cubit.generate,
              child: Container(
                height: 66,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(33),
                  gradient: PromptColors.accentGradient,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C28D9).withValues(alpha: 0.6),
                      blurRadius: 36,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.white, size: 24),
                    SizedBox(width: 12),
                    Text(
                      'Generate Prompt',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.18,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Result card
            if (state.showResult) ...[
              const SizedBox(height: 18),
              Container(
                decoration: BoxDecoration(
                  color: c.card,
                  border: Border.all(color: c.line, width: 1.5),
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'GENERATED PROMPT',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.92,
                            color: c.muted,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(const ClipboardData(
                              text:
                                  'A high-resolution photograph of soft morning light filtering through a minimalist interior, shallow depth of field, muted pastel palette, shot on 50mm, serene and airy mood.',
                            ));
                            cubit.copyResult();
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: c.accentSoft,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            child: Row(
                              children: [
                                Icon(Icons.content_copy, color: c.accentText, size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  state.resultCopied ? 'COPIED' : 'COPY',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.72,
                                    color: c.accentText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'A high-resolution photograph of soft morning light filtering through a minimalist interior, shallow depth of field, muted pastel palette, shot on 50mm, serene and airy mood.',
                      style: TextStyle(fontSize: 15, height: 1.5, color: c.ink),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 36),

            // Recent Creations
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Creations',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.46,
                    color: c.ink,
                  ),
                ),
                GestureDetector(
                  onTap: () => context.go(HistoryView.routeName),
                  child: Text(
                    'VIEW ALL',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.04,
                      color: c.accentText,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ...List.generate(_recentItems.length, (i) {
              final item = _recentItems[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [PromptColors.cardShadow],
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 86,
                        height: 86,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(13),
                          gradient: item.gradient,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.text,
                              style: TextStyle(fontSize: 14, height: 1.4, color: c.ink),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(text: item.text));
                                    cubit.copyRecent(i);
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: c.accentSoft,
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                                    child: Row(
                                      children: [
                                        Icon(Icons.content_copy, color: c.accentText, size: 13),
                                        const SizedBox(width: 6),
                                        Text(
                                          state.recentCopied == i ? 'COPIED' : 'COPY',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.88,
                                            color: c.accentText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 9),
                                Container(
                                  decoration: BoxDecoration(
                                    color: c.field,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                                  child: Row(
                                    children: [
                                      Icon(Icons.auto_awesome_mosaic_outlined, color: c.muted, size: 13),
                                      const SizedBox(width: 6),
                                      Text(
                                        'USE',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.88,
                                          color: c.muted,
                                        ),
                                      ),
                                    ],
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
              );
            }),
          ],
        );
      },
    );
  }
}
