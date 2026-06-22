import 'dart:async';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app_template/src/core/components/pickers/app_image_picker.dart';
import 'package:flutter_app_template/src/core/extensions/context_extension.dart';
import 'package:flutter_app_template/src/core/services/locator/locator.dart';
import 'package:flutter_app_template/src/features/image_to_prompt/history/presentation/views/history_detail_view.dart';
import 'package:flutter_app_template/src/features/image_to_prompt/history/presentation/views/history_view.dart';
import 'package:flutter_app_template/src/features/image_to_prompt/infrastructure/image_prompt_repo.dart';
import 'package:flutter_app_template/src/features/image_to_prompt/infrastructure/image_url_fetcher.dart';
import 'package:flutter_app_template/src/features/image_to_prompt/presentation/cubit/image_to_prompt_cubit.dart';
import 'package:flutter_app_template/src/features/image_to_prompt/presentation/prompt_colors.dart';
import 'package:flutter_app_template/src/features/image_to_prompt/presentation/widgets/language_picker_sheet.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

String _guessMimeType(String path) {
  final ext = path.split('.').last.toLowerCase();
  switch (ext) {
    case 'png':
      return 'image/png';
    case 'webp':
      return 'image/webp';
    case 'heic':
      return 'image/heic';
    case 'gif':
      return 'image/gif';
    default:
      return 'image/jpeg';
  }
}

class CreateView extends StatefulWidget {
  static const routeName = '/image-to-prompt/create';
  const CreateView({super.key});

  @override
  State<CreateView> createState() => _CreateViewState();
}

class _CreateViewState extends State<CreateView> with SingleTickerProviderStateMixin {
  final cubit = locator<ImageToPromptCubit>();
  final _urlController = TextEditingController();
  final _scrollController = ScrollController();

  late final AnimationController _resultController;
  late final Animation<Offset> _resultSlideAnimation;
  late final Animation<double> _resultFadeAnimation;
  bool _wasShowingResult = false;
  bool _isDragging = false;
  late int _lastScrollTopTick = cubit.state.scrollToTopTick;
  final _resultKey = GlobalKey();

  void _scrollToResult() {
    final resultContext = _resultKey.currentContext;
    if (resultContext != null) {
      Scrollable.ensureVisible(
        resultContext,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
        alignment: 0.1,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _urlController.text = cubit.state.imageUrl;
    _wasShowingResult = cubit.state.showResult;

    _resultController = AnimationController(duration: const Duration(milliseconds: 2000), vsync: this);
    _resultSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _resultController, curve: Curves.easeOutCubic));
    _resultFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _resultController, curve: Curves.easeOutCubic));

    if (_wasShowingResult) _resultController.value = 1;
  }

  @override
  void dispose() {
    _urlController.dispose();
    _scrollController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(PromptColors c) async {
    final file = await AppImagePicker.showPopUp(context: context, c: c);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (bytes.lengthInBytes > ImageUrlFetcher.maxBytes) {
      if (!mounted) return;
      showTopAlert('Image is too large (max 8MB).', isError: true);
      return;
    }
    cubit.setPickedImage(bytes, _guessMimeType(file.name));
    _urlController.clear();
  }

  Future<void> _handleDroppedFiles(List<XFile> files) async {
    if (files.isEmpty) return;
    final file = files.first;
    final bytes = await file.readAsBytes();
    if (bytes.lengthInBytes > ImageUrlFetcher.maxBytes) {
      if (!mounted) return;
      showTopAlert('Image is too large (max 8MB).', isError: true);
      return;
    }
    cubit.setPickedImage(bytes, _guessMimeType(file.name));
    _urlController.clear();
  }

  Future<void> _pasteLink() async {
    final clip = await Clipboard.getData(Clipboard.kTextPlain);
    final text = clip?.text?.trim();
    if (text == null || text.isEmpty) return;
    cubit.pasteImageUrl(text);
  }

  Future<void> _pickLanguage(PromptColors c) async {
    final selected = await showLanguagePickerSheet(context: context, c: c, current: cubit.state.outputLanguage);
    if (selected != null) cubit.setOutputLanguage(selected);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ImageToPromptCubit, ImageToPromptState>(
      bloc: cubit,
      listener: (context, state) {
        if (state.showResult && !_wasShowingResult) {
          _resultController.forward(from: 0);
          Future.delayed(const Duration(milliseconds: 100), _scrollToResult);
        }
        _wasShowingResult = state.showResult;

        if (state.scrollToTopTab == 0 && state.scrollToTopTick != _lastScrollTopTick) {
          _lastScrollTopTick = state.scrollToTopTick;
          if (_scrollController.hasClients) {
            _scrollController.animateTo(0, duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
          }
        }
      },
      builder: (context, state) {
        if (_urlController.text != state.imageUrl) {
          _urlController.text = state.imageUrl;
        }
        final c = PromptColors(state.darkMode);
        final recentItems = state.history.take(8).toList();

        return Scaffold(
          backgroundColor: c.page,
          body: ListView(
            controller: _scrollController,
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

              // Upload zone / preview
              DropTarget(
                onDragDone: (detail) => _handleDroppedFiles(detail.files),
                onDragEntered: (_) => setState(() => _isDragging = true),
                onDragExited: (_) => setState(() => _isDragging = false),
                child: state.isFetchingUrlPreview && state.pickedImageBytes == null
                    ? Container(
                        width: double.infinity,
                        height: 220,
                        decoration: BoxDecoration(color: c.field, borderRadius: BorderRadius.circular(20)),
                        child: Center(child: CircularProgressIndicator(color: c.accentText)),
                      )
                    : state.pickedImageBytes != null
                    ? Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.memory(
                        state.pickedImageBytes!,
                        width: double.infinity,
                        height: 220,
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (state.imageUrl.isNotEmpty)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.public, color: Colors.white, size: 13),
                              const SizedBox(width: 5),
                              Text(
                                'FROM URL',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: GestureDetector(
                        onTap: cubit.clearPickedImage,
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: GestureDetector(
                        onTap: state.isGenerating ? null : () => _pickImage(c),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Text(
                            'CHANGE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
                    : GestureDetector(
                  onTap: state.isGenerating ? null : () => _pickImage(c),
                  child: DottedBorder(
                    borderType: BorderType.RRect,
                    radius: const Radius.circular(20),
                    dashPattern: const [8, 6],
                    color: _isDragging ? c.accentText : c.line,
                    strokeWidth: _isDragging ? 2.5 : 2,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 20),
                      decoration: BoxDecoration(
                        color: _isDragging
                            ? c.accentText.withValues(alpha: 0.08)
                            : const Color(0xFF7C3AED).withValues(alpha: 0.035),
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
                            child: Icon(
                              _isDragging ? Icons.file_download_outlined : Icons.image_outlined,
                              color: c.accentText,
                              size: 34,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            _isDragging ? 'DROP TO UPLOAD' : 'UPLOAD IMAGE',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.4,
                              color: c.muted,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tap to browse or drag & drop',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: c.muted.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
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
                        onChanged: cubit.setImageUrl,
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
                    GestureDetector(
                      onTap: () => _pasteLink(),
                      child: Icon(Icons.link, color: c.accentText, size: 22),
                    ),
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
                children: ImagePromptModelTier.values.map((tier) {
                  final selected = state.selectedModel == tier;
                  return GestureDetector(
                    onTap: () => cubit.selectModel(tier),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
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
                      child: Text(
                        tier.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.84,
                          height: 1,
                          color: selected ? Colors.white : c.muted,
                        ),
                      ),
                    ),
                  );
                }).toList(),
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
              GestureDetector(
                onTap: () => _pickLanguage(c),
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
                      Row(
                        children: [
                          Icon(Icons.language, color: c.accentText, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            state.outputLanguage,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: c.ink,
                            ),
                          ),
                        ],
                      ),
                      Icon(Icons.keyboard_arrow_down, color: c.muted, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Generate button
              GestureDetector(
                onTap: state.isGenerating ? null : cubit.generate,
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (state.isGenerating)
                        const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                        )
                      else
                        const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        state.isGenerating ? 'Generating...' : 'Generate Prompt',
                        style: const TextStyle(
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
                SlideTransition(
                  key: _resultKey,
                  position: _resultSlideAnimation,
                  child: FadeTransition(
                    opacity: _resultFadeAnimation,
                    child: Container(
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
                              Row(
                                children: [
                                  if (!state.autoSave && !state.resultSaved && !state.isGenerating) ...[
                                    GestureDetector(
                                      onTap: cubit.saveCurrentResult,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: c.accentSoft,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                        child: Row(
                                          children: [
                                            Icon(Icons.save_outlined, color: c.accentText, size: 14),
                                            const SizedBox(width: 6),
                                            Text(
                                              'SAVE',
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
                                    const SizedBox(width: 8),
                                  ],
                                  GestureDetector(
                                    onTap: () {
                                      Clipboard.setData(ClipboardData(text: state.generatedPrompt));
                                      cubit.copyResult();
                                      showTopAlert('Copied to clipboard');
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
                            ],
                          ),
                          const SizedBox(height: 10),
                          _StreamingPromptText(
                            text: state.generatedPrompt,
                            isStreaming: state.isGenerating,
                            style: TextStyle(fontSize: 15, height: 1.5, color: c.ink),
                            accent: c.accentText,
                          ),
                        ],
                      ),
                    ),
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
              if (recentItems.isEmpty)
                Container(
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [PromptColors.cardShadow],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'Your generated prompts will show up here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: c.muted),
                    ),
                  ),
                )
              else
                ...List.generate(recentItems.length, (i) {
                  final item = recentItems[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: GestureDetector(
                      onTap: () => context.push(HistoryDetailView.routeName, extra: item),
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
                          ClipRRect(
                            borderRadius: BorderRadius.circular(13),
                            child: Image.memory(
                              item.imageBytes ?? Uint8List(0),
                              width: 86,
                              height: 86,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.prompt,
                                  style: TextStyle(fontSize: 14, height: 1.4, color: c.ink),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: c.accentSoft,
                                        borderRadius: BorderRadius.circular(9),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      child: Text(
                                        item.tier.label,
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.5,
                                          color: c.accentText,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: c.field,
                                        borderRadius: BorderRadius.circular(9),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.language, size: 10, color: c.muted),
                                          const SizedBox(width: 3),
                                          Text(
                                            item.outputLanguage,
                                            style: TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.3,
                                              color: c.muted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        Clipboard.setData(ClipboardData(text: item.prompt));
                                        cubit.copyRecent(i);
                                        showTopAlert('Copied to clipboard');
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
                                    GestureDetector(
                                      onTap: () => cubit.useHistoryEntry(item.id),
                                      child: Container(
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
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}

/// Reveals the generated prompt with a typewriter effect so the text appears to
/// be written in real time. On platforms where the SSE response streams in
/// (mobile) the target [text] grows chunk-by-chunk and the cursor trails just
/// behind it; where the response is buffered (web) the full text arrives at
/// once and is still revealed progressively. A blinking caret shows while the
/// model is still writing; once finished the text becomes selectable so it can
/// be copied by selection — not just via the Copy button.
class _StreamingPromptText extends StatefulWidget {
  final String text;
  final bool isStreaming;
  final TextStyle style;
  final Color accent;

  const _StreamingPromptText({
    required this.text,
    required this.isStreaming,
    required this.style,
    required this.accent,
  });

  @override
  State<_StreamingPromptText> createState() => _StreamingPromptTextState();
}

class _StreamingPromptTextState extends State<_StreamingPromptText> {
  int _visible = 0;
  Timer? _typeTimer;
  Timer? _blinkTimer;
  bool _cursorOn = true;

  bool get _active => widget.isStreaming || _visible < widget.text.length;

  @override
  void initState() {
    super.initState();
    // This widget only mounts once per generation (the result card is removed
    // from the tree between generations), so always reveal from scratch here —
    // even if, by the time this first builds, the network response already
    // finished (e.g. web buffers the whole SSE body before delivering it),
    // we still want the typewriter effect to play rather than jumping straight
    // to the final text.
    _visible = 0;
    _ensureTyping();
    _blinkTimer = Timer.periodic(const Duration(milliseconds: 530), (_) {
      if (mounted && _active) setState(() => _cursorOn = !_cursorOn);
    });
  }

  void _ensureTyping() {
    _typeTimer ??= Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (_visible >= widget.text.length) {
        if (!widget.isStreaming) {
          _typeTimer?.cancel();
          _typeTimer = null;
          if (mounted) setState(() {}); // drop the caret, switch to selectable
        }
        return;
      }
      // Catch up faster when far behind so big chunks don't lag the caret.
      final remaining = widget.text.length - _visible;
      final step = remaining > 80 ? 4 : 2;
      setState(() => _visible = (_visible + step).clamp(0, widget.text.length));
    });
  }

  @override
  void didUpdateWidget(covariant _StreamingPromptText oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new generation replaces the text with a different/shorter prefix.
    if (widget.text.length < oldWidget.text.length && !widget.text.startsWith(oldWidget.text)) {
      _visible = 0;
    }
    if (_visible > widget.text.length) _visible = widget.text.length;
    _ensureTyping();
  }

  @override
  void dispose() {
    _typeTimer?.cancel();
    _blinkTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_active) {
      return SelectableText(widget.text, style: widget.style);
    }
    final shown = widget.text.substring(0, _visible.clamp(0, widget.text.length));
    return Text.rich(
      TextSpan(
        text: shown,
        style: widget.style,
        children: [
          if (_cursorOn) TextSpan(text: '▌', style: widget.style.copyWith(color: widget.accent)),
        ],
      ),
    );
  }
}
