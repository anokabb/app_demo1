import 'package:flutter/material.dart';
import 'package:flutter_app_template/src/core/components/pop_up/slide_up_pop_up.dart';
import 'package:flutter_app_template/src/core/components/widgets/tap_opacity.dart';
import 'package:flutter_app_template/src/core/constants/hive_config.dart';
import 'package:flutter_app_template/src/core/extensions/context_extension.dart';
import 'package:flutter_app_template/src/core/services/locator/locator.dart';
import 'package:flutter_app_template/src/core/services/remote_config/remote_config_service.dart';
import 'package:flutter_app_template/src/features/image_to_prompt/presentation/prompt_colors.dart';
import 'package:url_launcher/url_launcher.dart';

/// Name of the third-party AI provider the image is sent to. Kept in one place
/// so the in-app disclosure, the settings row and the privacy policy all say
/// exactly the same thing.
const kAiProviderName = 'Google Gemini API';
const kAiProviderCompany = 'Google LLC';
const kAiProviderPrivacyUrl = 'https://policies.google.com/privacy';

/// Explains what is sent to the third-party AI service, who receives it, and
/// asks for permission before anything leaves the device.
///
/// Required by App Store Review Guidelines 5.1.1(i) and 5.1.2(i): an app may
/// only transmit personal data to a third-party AI service after it discloses
/// what is sent, identifies the recipient, and obtains the user's consent.
class AiDisclosureSheet extends StatelessWidget {
  /// Versioned so that changing what we send (a new provider, new fields)
  /// re-prompts everyone instead of silently riding on an old agreement.
  static const _consentKey = 'itp_ai_consent_v1';

  final PromptColors c;

  /// Consent mode shows Decline / Agree. Info mode is the re-readable version
  /// opened from Settings, where the action is withdrawing instead of giving.
  final bool isInfoMode;
  final bool hasConsent;

  const AiDisclosureSheet({
    super.key,
    required this.c,
    this.isInfoMode = false,
    this.hasConsent = false,
  });

  static bool get hasConsented => settingsBox.get(_consentKey, defaultValue: false) == true;

  static void revokeConsent() => settingsBox.put(_consentKey, false);

  /// Shows the disclosure if consent hasn't been given yet, and returns whether
  /// it is now safe to send the image. Callers must not transmit anything when
  /// this resolves to `false`.
  static Future<bool> ensureConsent({BuildContext? context, required PromptColors c}) async {
    if (hasConsented) return true;
    final agreed = await SlideUpPopUp.show<bool>(
      context: context,
      backgroundColor: c.card,
      borderRadius: BorderRadius.circular(24),
      child: AiDisclosureSheet(c: c),
    );
    if (agreed == true) {
      settingsBox.put(_consentKey, true);
      return true;
    }
    return false;
  }

  /// Re-opens the disclosure read-only, with the option to withdraw consent.
  static Future<void> showInfo({BuildContext? context, required PromptColors c}) async {
    final withdraw = await SlideUpPopUp.show<bool>(
      context: context,
      backgroundColor: c.card,
      borderRadius: BorderRadius.circular(24),
      child: AiDisclosureSheet(c: c, isInfoMode: true, hasConsent: hasConsented),
    );
    if (withdraw == true) {
      revokeConsent();
      showTopAlert('Consent withdrawn. You will be asked again before your next generation.');
    }
  }

  static Future<void> _open(String url) async {
    if (url.isEmpty) return;
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      showTopAlert("Couldn't open that link.", isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final privacyUrl = locator<RemoteConfigService>().data.settings.privacyPolicyUrl;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: c.iconBox, shape: BoxShape.circle),
              child: Icon(Icons.cloud_upload_outlined, color: c.accentText, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              isInfoMode ? 'How your image is used' : 'Your image will be sent to $kAiProviderName',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, height: 1.25, color: c.ink),
            ),
            const SizedBox(height: 10),
            Text(
              'PromptGen cannot describe your image on this device. To create a prompt it has to '
              'send the image to a third-party AI service. Here is exactly what happens.',
              style: TextStyle(fontSize: 14, color: c.muted, height: 1.45),
            ),
            const SizedBox(height: 20),

            _DisclosureRow(
              c: c,
              icon: Icons.image_outlined,
              title: 'What is sent',
              body: 'The single image you select or capture, plus the output language and detail '
                  'level you chose. Nothing else from your device is included.',
            ),
            _DisclosureRow(
              c: c,
              icon: Icons.business_outlined,
              title: 'Who receives it',
              body: '$kAiProviderCompany, through the $kAiProviderName. Google processes the image '
                  'only to return your generated prompt, under the Google APIs Terms of Service '
                  'and the Google Privacy Policy.',
            ),
            _DisclosureRow(
              c: c,
              icon: Icons.lock_outline,
              title: 'What is never sent',
              body: 'No name, email address, account, contacts, photo library, or location. '
                  'PromptGen has no account system and stores no images on its own servers — '
                  'your history stays on this device only.',
            ),
            _DisclosureRow(
              c: c,
              icon: Icons.settings_backup_restore,
              title: 'You stay in control',
              body: 'Nothing is sent until you tap Generate, and you can withdraw this permission '
                  'at any time in Profile → AI & Data Sharing.',
              isLast: true,
            ),

            const SizedBox(height: 6),
            Wrap(
              spacing: 18,
              runSpacing: 8,
              children: [
                if (privacyUrl.isNotEmpty)
                  _LinkText(c: c, label: 'PromptGen Privacy Policy', onTap: () => _open(privacyUrl)),
                _LinkText(
                  c: c,
                  label: 'Google Privacy Policy',
                  onTap: () => _open(kAiProviderPrivacyUrl),
                ),
              ],
            ),
            const SizedBox(height: 22),

            if (isInfoMode)
              Row(
                children: [
                  Expanded(
                    child: _ConsentButton(
                      c: c,
                      label: 'Close',
                      filled: !hasConsent,
                      onTap: () => Navigator.of(context).pop(false),
                    ),
                  ),
                  if (hasConsent) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ConsentButton(
                        c: c,
                        label: 'Withdraw',
                        filled: true,
                        onTap: () => Navigator.of(context).pop(true),
                      ),
                    ),
                  ],
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _ConsentButton(
                      c: c,
                      label: "Don't send",
                      filled: false,
                      onTap: () => Navigator.of(context).pop(false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: _ConsentButton(
                      c: c,
                      label: 'Agree and send',
                      filled: true,
                      onTap: () => Navigator.of(context).pop(true),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _DisclosureRow extends StatelessWidget {
  final PromptColors c;
  final IconData icon;
  final String title;
  final String body;
  final bool isLast;

  const _DisclosureRow({
    required this.c,
    required this.icon,
    required this.title,
    required this.body,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 14 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 18, color: c.accentText),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.ink),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: TextStyle(fontSize: 13, height: 1.45, color: c.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkText extends StatelessWidget {
  final PromptColors c;
  final String label;
  final VoidCallback onTap;

  const _LinkText({required this.c, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TapOpacity(
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: c.accentText,
          decoration: TextDecoration.underline,
          decorationColor: c.accentText,
        ),
      ),
    );
  }
}

class _ConsentButton extends StatelessWidget {
  final PromptColors c;
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _ConsentButton({
    required this.c,
    required this.label,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TapOpacity(
      onTap: onTap,
      child: Container(
        height: 50,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: filled ? null : c.field,
          gradient: filled ? PromptColors.accentGradient : null,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
