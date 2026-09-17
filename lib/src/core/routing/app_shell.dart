import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_app_template/src/core/gen/assets.gen.dart';
import 'package:flutter_app_template/src/core/services/locator/locator.dart';
import 'package:flutter_app_template/src/core/services/purchases/subscription_cubit.dart';
import 'package:flutter_app_template/src/features/image_to_prompt/presentation/cubit/image_to_prompt_cubit.dart';
import 'package:flutter_app_template/src/features/image_to_prompt/presentation/prompt_colors.dart';
import 'package:flutter_app_template/src/features/image_to_prompt/settings/presentation/views/settings_view.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

// ─── ImageToPromptShell ───────────────────────────────────────────────────────

class ImageToPromptShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const ImageToPromptShell({super.key, required this.navigationShell});

  @override
  State<ImageToPromptShell> createState() => _ImageToPromptShellState();
}

class _ImageToPromptShellState extends State<ImageToPromptShell> {
  final cubit = locator<ImageToPromptCubit>();

  @override
  void initState() {
    super.initState();
    // RevenueCat (and therefore the paywall) isn't available on web, see main.dart.
    if (!kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) => locator<SubscriptionCubit>().showAppOpenPaywall());
    }
  }

  void _onTabTap(int index) {
    // goBranch first: the scroll-to-top tick has to be emitted *after* the
    // target branch is active, otherwise the listener on the destination tab
    // never observes the tick change.
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
    cubit.requestScrollToTop(index);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ImageToPromptCubit, ImageToPromptState>(
      bloc: cubit,
      builder: (context, state) {
        final c = PromptColors(state.darkMode);
        // Bottom nav is a Positioned overlay, not Scaffold.bottomNavigationBar, so it
        // doesn't get pushed off-screen by the keyboard automatically — hide it manually.
        final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
        // iOS's home-indicator safe-area inset would otherwise stack on top of the
        // floating nav's own bottom margin, making it sit far closer to the left/right
        // margins than the bottom one. Android's nav-bar inset is kept as-is.
        final isIOS = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
        return Scaffold(
          backgroundColor: c.page,
          body: SafeArea(
            // The header paints its own gradient behind the status bar and insets its
            // content manually, so the Stack itself shouldn't reserve top safe area.
            top: false,
            bottom: !isIOS,
            child: Stack(
              children: [
                Column(
                  children: [
                    _PromptHeader(
                      c: c,
                      onSettings: () => context.push(SettingsView.routeName),
                    ),
                    // `StatefulNavigationShell` carries a GlobalKey owned by go_router.
                    // Wrapping it in an AnimatedSwitcher keeps the outgoing child
                    // mounted during the cross-fade, so two widgets end up sharing
                    // that one GlobalKey ("Duplicate GlobalKey detected in widget
                    // tree") and every branch loses its state on each tab switch.
                    // The shell must therefore be rendered directly, with no
                    // keyed/animated wrapper around it.
                    Expanded(child: widget.navigationShell),
                  ],
                ),
                if (!keyboardVisible)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _PromptBottomNav(
                      currentIndex: widget.navigationShell.currentIndex,
                      c: c,
                      onTap: _onTabTap,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PromptHeader extends StatelessWidget {
  final PromptColors c;
  final VoidCallback onSettings;
  const _PromptHeader({required this.c, required this.onSettings});

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(22, topInset + 20, 22, 16),
      decoration: BoxDecoration(
        gradient: c.dark
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF7C3AED).withValues(alpha: 0.18),
                  Colors.transparent,
                ],
              )
            : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF0EBFB),
                  Color(0xFFF8F7F3),
                ],
              ),
      ),
      child: Row(
        children: [
          Expanded(child: _PromptLogo(c: c)),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onSettings,
            child: Container(
              padding: const EdgeInsets.all(6),
              color: Colors.transparent,
              child: Icon(Icons.settings_outlined, color: c.accentText, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}

class _PromptLogo extends StatelessWidget {
  final PromptColors c;
  const _PromptLogo({required this.c});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Assets.images.appIconTransparent.image(width: 30, height: 30),
        const SizedBox(width: 9),
        Flexible(
          child: Text(
            'PromptGen',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.42,
              color: c.accentText,
            ),
          ),
        ),
      ],
    );
  }
}

class _PromptBottomNav extends StatelessWidget {
  static const _navBarHeight = 74.0;
  static const _createOverhang = 20.0;

  final int currentIndex;
  final PromptColors c;
  final ValueChanged<int> onTap;
  const _PromptBottomNav({
    required this.currentIndex,
    required this.c,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 124,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [c.page.withValues(alpha: 0), c.page],
          stops: const [0.0, 0.45],
        ),
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        // The CREATE button is raised 20px above the nav bar card. It has to
        // live inside its parent's bounds — hit testing rejects anything outside
        // them — so this box is the card's height plus that overhang, and the
        // card itself is pinned to the bottom of it.
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          height: _navBarHeight + _createOverhang,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: _navBarHeight,
                child: Container(
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3C1E78).withValues(alpha: 0.25),
                        blurRadius: 40,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 38),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _PromptNavItem(
                          icon: Icons.history,
                          label: 'HISTORY',
                          isActive: currentIndex == 1,
                          c: c,
                          onTap: () => onTap(1),
                        ),
                        const SizedBox(width: 58),
                        _PromptNavItem(
                          icon: Icons.person_outline,
                          label: 'PROFILE',
                          isActive: currentIndex == 2,
                          c: c,
                          onTap: () => onTap(2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTap(0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: PromptColors.accentGradient,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6C28D9).withValues(alpha: 0.65),
                                blurRadius: 26,
                                offset: const Offset(0, 14),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 26),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'CREATE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                            color: currentIndex == 0 ? c.accentText : PromptColors.idle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PromptNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final PromptColors c;
  final VoidCallback onTap;
  const _PromptNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.c,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? c.accentText : PromptColors.idle;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 23),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
