import 'package:cached_network_image/cached_network_image.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app_template/src/core/components/pop_up/slide_up_pop_up.dart';
import 'package:flutter_app_template/src/core/components/widgets/tap_opacity.dart';
import 'package:flutter_app_template/src/core/extensions/context_extension.dart';
import 'package:flutter_app_template/src/core/services/theme/app_colors.dart';
import 'package:flutter_app_template/src/core/services/theme/app_theme.dart';
import 'package:flutter_app_template/src/features/image_to_prompt/presentation/prompt_colors.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

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

  /// Asks the user for a source, then returns the picked file.
  ///
  /// The source sheet is dismissed *before* the system picker is presented.
  /// Launching `UIImagePickerController` from a route that is itself still
  /// being torn down leaves the camera presented over a dying view controller,
  /// which is what produced the black camera screen App Review saw on iPad.
  static Future<XFile?> showPopUp({
    required BuildContext context,
    required PromptColors c,
  }) async {
    final source = await _showSourceSheet(context: context, c: c);
    if (source == null) return null;
    if (!context.mounted) return null;

    // Let the sheet's dismiss transition finish so the system picker is
    // presented from a settled view controller.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!context.mounted) return null;

    try {
      // No permission pre-check here on purpose: image_picker_ios already calls
      // `AVCaptureDevice requestAccessForMediaType:` and surfaces a refusal as
      // the `camera_access_denied` error below, so asking again would only put
      // a second, redundant gate in front of the native prompt.
      return await _pickImage(source);
    } on PlatformException catch (e) {
      // A refusal comes back as an error rather than as UI, so it has to be
      // surfaced here — otherwise the tap looks like it did nothing. The other
      // codes cover devices with no usable camera.
      if (e.code == 'camera_access_denied') {
        if (context.mounted) await _showCameraDeniedSheet(context, c);
      } else {
        showTopAlert("Couldn't open the camera on this device.", isError: true);
      }
      return null;
    } catch (_) {
      showTopAlert("Couldn't open the image picker. Please try again.", isError: true);
      return null;
    }
  }

  static Future<ImageSource?> _showSourceSheet({
    required BuildContext context,
    required PromptColors c,
  }) {
    return SlideUpPopUp.show<ImageSource?>(
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
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            Divider(color: c.line, height: 1, indent: 20, endIndent: 20),
            _PickerOption(
              c: c,
              icon: Icons.photo_library_rounded,
              label: context.localization.fromGallery,
              subtitle: context.localization.fromGallerySubtitle,
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  static Future<void> _showCameraDeniedSheet(BuildContext context, PromptColors c) async {
    final openSettings = await SlideUpPopUp.show<bool>(
      context: context,
      backgroundColor: c.card,
      borderRadius: BorderRadius.circular(24),
      child: _CameraDeniedSheet(c: c),
    );
    if (openSettings == true) await openAppSettings();
  }

  /// Longest edge a picked image is downscaled to before it ever reaches memory.
  /// Full-resolution camera shots (12MP+) are pure waste here: the bytes are
  /// held in a non-lazy Hive box (so every history image stays resident in RAM)
  /// and are base64-encoded into the model request.
  static const _maxDimension = 1536.0;

  /// JPEG re-encode quality — visually lossless for prompt generation while
  /// cutting the payload by roughly an order of magnitude.
  static const _imageQuality = 85;

  static Future<XFile?> _pickImage(ImageSource source) async {
    return ImagePicker().pickImage(
      source: source,
      maxWidth: _maxDimension,
      maxHeight: _maxDimension,
      imageQuality: _imageQuality,
    );
  }
}

class _CameraDeniedSheet extends StatelessWidget {
  final PromptColors c;

  const _CameraDeniedSheet({required this.c});

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
            decoration: BoxDecoration(color: c.iconBox, shape: BoxShape.circle),
            child: Icon(Icons.no_photography_outlined, color: c.accentText, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            'Camera access is off',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: c.ink),
          ),
          const SizedBox(height: 8),
          Text(
            'PromptGen needs camera access to take a photo. You can turn it on in Settings, '
            'or pick an image from your photo library instead.',
            style: TextStyle(fontSize: 14, color: c.muted, height: 1.4),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _SheetAction(
                  label: 'Not now',
                  c: c,
                  filled: false,
                  onTap: () => Navigator.of(context).pop(false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SheetAction(
                  label: 'Open Settings',
                  c: c,
                  filled: true,
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

class _SheetAction extends StatelessWidget {
  final String label;
  final PromptColors c;
  final bool filled;
  final VoidCallback onTap;

  const _SheetAction({
    required this.label,
    required this.c,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TapOpacity(
      onTap: onTap,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? null : c.field,
          gradient: filled ? PromptColors.accentGradient : null,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: filled ? Colors.white : c.muted,
          ),
        ),
      ),
    );
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
