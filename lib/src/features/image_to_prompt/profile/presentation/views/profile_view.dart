import 'package:flutter/material.dart';
import 'package:flutter_app_template/src/core/extensions/context_extension.dart';
import 'package:flutter_app_template/src/core/services/locator/locator.dart';
import 'package:flutter_app_template/src/core/services/remote_config/remote_config_service.dart';
import 'package:flutter_app_template/src/features/image_to_prompt/presentation/cubit/image_to_prompt_cubit.dart';
import 'package:flutter_app_template/src/features/image_to_prompt/presentation/prompt_colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileView extends StatefulWidget {
  static const routeName = '/image-to-prompt/profile';
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final cubit = locator<ImageToPromptCubit>();
  final _scrollController = ScrollController();

  static const _menuItems = [
    (icon: Icons.bookmark_outline, label: 'Saved Prompts'),
    (icon: Icons.workspace_premium_outlined, label: 'Subscription'),
    (icon: Icons.credit_card_outlined, label: 'Billing & Payment'),
    (icon: Icons.shield_outlined, label: 'Privacy & Security'),
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      // inAppWebView keeps the user inside the app (SFSafariViewController /
      // Chrome Custom Tab on mobile) instead of switching to the external browser.
      final launched = await launchUrl(uri, mode: LaunchMode.inAppWebView);
      if (!launched) throw Exception('Could not launch $url');
    } catch (e) {
      showTopError('Could not open the link');
    }
  }

  Future<void> _openEmail(String email) async {
    try {
      final launched = await launchUrl(Uri.parse('mailto:$email'));
      if (!launched) throw Exception('Could not launch mailto:$email');
    } catch (e) {
      showTopError('Could not open your email app');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ImageToPromptCubit, ImageToPromptState>(
      bloc: cubit,
      listenWhen: (prev, curr) => curr.scrollToTopTab == 2 && curr.scrollToTopTick != prev.scrollToTopTick,
      listener: (context, state) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(0, duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
        }
      },
      builder: (context, state) {
        final c = PromptColors(state.darkMode);
        final stats = [
          (state.history.length.toString(), 'PROMPTS'),
          (state.history.where((e) => e.isSaved).length.toString(), 'SAVED'),
          ('∞', 'CREDITS'),
        ];
        final settings = locator<RemoteConfigService>().data.settings;
        final legalRows = <_ProfileLink>[
          if (settings.privacyPolicyUrl.isNotEmpty)
            _ProfileLink(Icons.privacy_tip_outlined, 'Privacy Policy', () => _openUrl(settings.privacyPolicyUrl)),
          if (settings.termsOfServiceUrl.isNotEmpty)
            _ProfileLink(Icons.description_outlined, 'Terms of Service', () => _openUrl(settings.termsOfServiceUrl)),
          if (settings.aboutUrl.isNotEmpty)
            _ProfileLink(Icons.info_outline, 'About', () => _openUrl(settings.aboutUrl)),
          if (settings.helpAndSupportUrl.isNotEmpty)
            _ProfileLink(Icons.help_outline, 'Help & Support', () => _openUrl(settings.helpAndSupportUrl)),
          if (settings.contactUsEmail.isNotEmpty)
            _ProfileLink(Icons.mail_outline, 'Contact Us', () => _openEmail(settings.contactUsEmail)),
        ];
        return Scaffold(
          backgroundColor: c.page,
          body: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 130),
            children: [
              Text(
                'Profile',
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.33,
                  height: 1.04,
                  color: c.ink,
                ),
              ),
              const SizedBox(height: 22),

              // Profile card
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: PromptColors.accentGradient,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C28D9).withValues(alpha: 0.55),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.22),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
                      ),
                      child: const Center(
                        child: Text(
                          'AC',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Alex Carter',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            '@alexcarter',
                            style: TextStyle(fontSize: 13, color: Color(0xCCFFFFFF)),
                          ),
                          const SizedBox(height: 9),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.workspace_premium, color: Color(0xFFF0B429), size: 12),
                                SizedBox(width: 5),
                                Text(
                                  'PRO MEMBER',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.66,
                                    color: Color(0xFF5B16E0),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Stats row
              Row(
                children: List.generate(stats.length, (i) {
                  final s = stats[i];
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: i < stats.length - 1 ? 12 : 0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: c.card,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [PromptColors.cardShadow],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(
                              s.$1,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: c.ink,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              s.$2,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.44,
                                color: c.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 28),

              // Menu
              Container(
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [PromptColors.cardShadow],
                ),
                clipBehavior: Clip.hardEdge,
                child: Column(
                  children: List.generate(_menuItems.length, (i) {
                    final item = _menuItems[i];
                    return _ProfileRow(
                      icon: item.icon,
                      title: item.label,
                      c: c,
                      isFirst: i == 0,
                      onTap: () {},
                    );
                  }),
                ),
              ),

              if (legalRows.isNotEmpty) ...[
                const SizedBox(height: 18),
                _ProfileSectionLabel(label: 'LEGAL & SUPPORT', c: c),
                Container(
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [PromptColors.cardShadow],
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: Column(
                    children: List.generate(legalRows.length, (i) {
                      final row = legalRows[i];
                      return _ProfileRow(
                        icon: row.icon,
                        title: row.title,
                        c: c,
                        isFirst: i == 0,
                        onTap: row.onTap,
                      );
                    }),
                  ),
                ),
              ],

              const SizedBox(height: 18),
              _ProfileSectionLabel(label: 'ABOUT', c: c),
              Container(
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [PromptColors.cardShadow],
                ),
                clipBehavior: Clip.hardEdge,
                child: Column(
                  children: [
                    _ProfileRow(icon: Icons.star_outline, title: 'Rate the app', c: c, isFirst: true),
                    _ProfileRow(icon: Icons.info_outline, title: 'App version', trailing: '2.4.0', c: c),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Log out
              Container(
                height: 56,
                decoration: BoxDecoration(
                  color: c.card,
                  border: Border.all(color: const Color(0xFFF0D4D4), width: 1.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text(
                    'Log Out',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                      color: Color(0xFFD14343),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileLink {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _ProfileLink(this.icon, this.title, this.onTap);
}

class _ProfileSectionLabel extends StatelessWidget {
  final String label;
  final PromptColors c;
  const _ProfileSectionLabel({required this.label, required this.c});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 12, top: 10),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.68,
          color: c.muted,
        ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String trailing;
  final PromptColors c;
  final bool isFirst;
  final VoidCallback? onTap;

  const _ProfileRow({
    required this.icon,
    required this.title,
    required this.c,
    this.trailing = '',
    this.isFirst = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!isFirst) Divider(color: c.line, thickness: 1, height: 1),
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: c.iconBox, borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: c.accentText, size: 20),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.ink)),
                ),
                if (trailing.isNotEmpty) ...[
                  Text(trailing, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.muted)),
                  const SizedBox(width: 6),
                ],
                if (onTap != null) Icon(Icons.chevron_right, color: c.line, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
