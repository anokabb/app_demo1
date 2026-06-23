import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_template/src/core/components/pop_up/slide_up_pop_up.dart';
import 'package:flutter_app_template/src/core/components/widgets/tap_opacity.dart';
import 'package:flutter_app_template/src/core/extensions/context_extension.dart';
import 'package:flutter_app_template/src/core/services/theme/app_colors.dart';
import 'package:flutter_app_template/src/core/services/theme/app_theme.dart';
import 'package:flutter_app_template/src/features/image_to_prompt/presentation/prompt_colors.dart';
import 'package:image_picker/image_picker.dart';

class AppImagePicker extends StatefulWidget {
  /// The aspect ratio of the image picker, default aspect ratio is 3:1.
  final double aspectRatio;
  final double? size;
  final String? imageUrl;
  final Function(String pickedImage)? onImagePicked;

  const AppImagePicker({
    super.key,
    this.size,
    this.imageUrl,
    this.onImagePicked,
    this.aspectRatio = 3 / 1,
  });

  @override
  State<AppImagePicker> createState() => _AppImagePickerState();

  static Future<XFile?> showPopUp({
    required BuildContext context,
    required PromptColors c,
  }) async {
    return await SlideUpPopUp.show<XFile?>(
      context: context,
      backgroundColor: c.card,
      borderRadius: BorderRadius.circular(24),
      child: Builder(
        builder: (context) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  context.localization.uploadImage,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: c.ink),
                ),
              ),
            ),
            _PickerOption(
              c: c,
              icon: Icons.camera_alt_rounded,
              label: context.localization.takePhoto,
              subtitle: context.localization.takePhotoSubtitle,
              onTap: () async {
                Navigator.of(context).pop(await _pickImage(ImageSource.camera));
              },
            ),
            Divider(color: c.line, height: 1, indent: 20, endIndent: 20),
            _PickerOption(
              c: c,
              icon: Icons.photo_library_rounded,
              label: context.localization.fromGallery,
              subtitle: context.localization.fromGallerySubtitle,
              onTap: () async {
                Navigator.of(context).pop(await _pickImage(ImageSource.gallery));
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  static Future<XFile?> _pickImage(ImageSource source) async {
    return ImagePicker().pickImage(source: source);
  }
}

class _PickerOption extends StatelessWidget {
  final PromptColors c;
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _PickerOption({
    required this.c,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TapOpacity(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: c.iconBox,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: c.accentText, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.ink),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: c.muted),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: c.muted, size: 22),
          ],
        ),
      ),
    );
  }
}

class _AppImagePickerState extends State<AppImagePicker> {
  Uint8List? _pickedImageBytes;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Center(
        child: AspectRatio(
          aspectRatio: widget.aspectRatio,
          child: CupertinoButton(
            onPressed: () {
              AppImagePicker.showPopUp(
                context: context,
                c: PromptColors(Theme.of(context).brightness == Brightness.dark),
              ).then(
                (file) async {
                  if (file != null) {
                    final bytes = await file.readAsBytes();
                    widget.onImagePicked?.call(file.path);
                    setState(() {
                      _pickedImageBytes = bytes;
                    });
                  }
                },
              );
            },
            padding: EdgeInsets.zero,
            minSize: 0,
            child: _pickedImageBytes != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.memory(
                      _pickedImageBytes!,
                      fit: BoxFit.cover,
                      width: widget.size ?? double.infinity,
                      height: widget.size,
                    ),
                  )
                : widget.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: CachedNetworkImage(
                          imageUrl: widget.imageUrl!,
                          fit: BoxFit.cover,
                          width: widget.size ?? double.infinity,
                          height: widget.size,
                        ),
                      )
                    : DottedBorder(
                        color: AppColors.lightBlue,
                        strokeWidth: 1,
                        dashPattern: const [10, 6],
                        radius: const Radius.circular(4),
                        borderType: BorderType.RRect,
                        padding: const EdgeInsets.all(12),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                textAlign: TextAlign.center,
                                context.localization.noImageSelected,
                                style: context.theme.appTextTheme.body3.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.lightBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
          ),
        ),
      ),
    );
  }
}
