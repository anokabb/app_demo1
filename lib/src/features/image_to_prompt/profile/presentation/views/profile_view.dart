import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_template/src/core/extensions/context_extension.dart';
import 'package:flutter_app_template/src/core/services/in_app_browser_service.dart';
import 'package:flutter_app_template/src/core/services/locator/locator.dart';
import 'package:flutter_app_template/src/core/services/purchases/revenue_cat_service.dart';
import 'package:flutter_app_template/src/core/services/purchases/subscription_cubit.dart';
import 'package:flutter_app_template/src/core/services/remote_config/remote_config_service.dart';
import 'package:flutter_app_template/src/features/image_to_prompt/history/presentation/views/history_view.dart';
import 'package:flutter_app_template/src/features/image_to_prompt/presentation/cubit/image_to_prompt_cubit.dart';
import 'package:flutter_app_template/src/features/image_to_prompt/presentation/prompt_colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileView extends StatefulWidget {
  static const routeName = '/image-to-prompt/profile';
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final cubit = locator<ImageToPromptCubit>();
  final _subscriptionCubit = locator<SubscriptionCubit>();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _rateApp() async {
    if (kIsWeb) return;
    final review = InAppReview.instance;
    if (await review.isAvailable()) {
      await review.requestReview();
    }
  }

  Future<void> _openUrl(String url) async {
    try {
      // url_launcher's inAppBrowserView presents SFSafariViewController with
      // .overFullScreen on iOS (looks like a left-to-right push), so iOS goes
      // through our own channel that presents it as a .pageSheet modal instead.
      // Android's Chrome Custom Tab already opens as a bottom modal by default.
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        await InAppBrowserService.open(url);
        return;
      }
      final uri = Uri.parse(url);
      final launched = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
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
        return BlocBuilder<SubscriptionCubit, SubscriptionState>(
          bloc: _subscriptionCubit,
          builder: (context, subState) => _buildBody(context, c, subState.isSubscriber),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, PromptColors c, bool isPro) {
    final credits = isPro ? '∞' : _subscriptionCubit.remainingFreeActions.toString();
    final stats = [
      (cubit.state.history.length.toString(), 'PROMPTS'),
      (cubit.state.history.length.toString(), 'SAVED'),
      (credits, 'CREDITS'),
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
                      child: Icon(
                        isPro ? Icons.workspace_premium_rounded : Icons.person_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Hi there 👋',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            isPro ? 'Thanks for being a Pro member' : 'You\'re on the free plan',
                            style: const TextStyle(fontSize: 13, color: Color(0xCCFFFFFF)),
                          ),
                          const SizedBox(height: 9),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isPro ? Icons.workspace_premium : Icons.bolt,
                                  color: const Color(0xFFF0B429),
                                  size: 12,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  isPro ? 'PRO MEMBER' : 'FREE PLAN',
                                  style: const TextStyle(
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
              if (!isPro) ...[
                const SizedBox(height: 24),
                _GetProButton(c: c, onTap: () => _subscriptionCubit.showPaywall(PaywallOffers.second_offer)),
              ],
              const SizedBox(height: 18),

              // Stats row
              Row(
                children: List.generate(stats.length, (i) {
                  final s = stats[i];
                  final isSavedTile = s.$2 == 'SAVED';
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: i < stats.length - 1 ? 12 : 0),
                      child: GestureDetector(
                        onTap: isSavedTile ? () => context.go(HistoryView.routeName) : null,
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
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),

              if (legalRows.isNotEmpty) ...[
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
                    _ProfileRow(icon: Icons.star_outline, title: 'Rate the app', c: c, isFirst: true, onTap: _rateApp),
                    _ProfileRow(icon: Icons.info_outline, title: 'App version', trailing: '2.4.0', c: c),
                  ],
                ),
              ),
            ],
          ),
        );
  }
}

class _ProfileLink {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _ProfileLink(this.icon, this.title, this.onTap);
}

/// A deliberately understated "Get Pro" call-to-action: a dashed outline with
/// the app's accent (no solid primary fill) that breathes with a slow, smooth
/// scale pulse and presses in on tap. The gentle motion draws the eye without
/// the carnival feel of a shimmering gradient.
class _GetProButton extends StatefulWidget {
  final VoidCallback onTap;
  final PromptColors c;
  const _GetProButton({required this.onTap, required this.c});

  @override
  State<_GetProButton> createState() => _GetProButtonState();
}

class _GetProButtonState extends State<_GetProButton> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _scale;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(duration: const Duration(milliseconds: 1600), vsync: this)..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final accent = c.accentText;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
        child: ScaleTransition(
          scale: _scale,
          child: DottedBorder(
            borderType: BorderType.RRect,
            radius: const Radius.circular(16),
            dashPattern: const [7, 5],
            strokeWidth: 1.5,
            color: accent.withValues(alpha: 0.6),
            child: Container(
              height: 46,
              width: double.infinity,
              decoration: BoxDecoration(
                color: c.accentSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.workspace_premium_rounded, color: accent, size: 17),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Get Pro Version',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                          color: accent,
                        ),
                      ),
                      Text(
                        'Unlock unlimited prompts',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w500,
                          color: accent.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, color: accent, size: 15),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
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
