import 'package:flutter/material.dart';
import 'package:flutter_app_template/src/core/constants/hive_config.dart';
import 'package:flutter_app_template/src/core/routing/app_router.dart';
import 'package:flutter_app_template/src/features/image_to_prompt/presentation/prompt_colors.dart';
import 'package:flutter_app_template/src/features/onboarding/presentation/views/splash_view.dart';
import 'package:go_router/go_router.dart';

class _OnboardingPageData {
  final IconData icon;
  final String title;
  final String subtitle;

  const _OnboardingPageData({required this.icon, required this.title, required this.subtitle});
}

const _pages = [
  _OnboardingPageData(
    icon: Icons.image_search_rounded,
    title: 'Turn Any Image Into\nthe Perfect Prompt',
    subtitle: 'Upload a photo and get a ready-to-use AI prompt in seconds.',
  ),
  _OnboardingPageData(
    icon: Icons.auto_awesome_rounded,
    title: 'Works With Every\nAI Model',
    subtitle: 'Generate prompts tuned for Midjourney, DALL·E, Stable Diffusion and more.',
  ),
  _OnboardingPageData(
    icon: Icons.history_rounded,
    title: 'Your History,\nAlways at Hand',
    subtitle: 'Every prompt you create is saved and ready to reuse anytime.',
  ),
];

class OnboardingView extends StatefulWidget {
  static const String routeName = '/onboarding';

  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final _pageController = PageController();
  int _index = 0;

  bool get _isLastPage => _index == _pages.length - 1;

  Future<void> _finish() async {
    await SplashView.setOnboardingCompleted();
    if (!mounted) return;
    context.go(AppRouter.defaultRoute);
  }

  void _next() {
    if (_isLastPage) {
      _finish();
      return;
    }
    _pageController.nextPage(duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = PromptColors(settingsBox.get('itp_dark_mode', defaultValue: false) == true);
    return Scaffold(
      backgroundColor: c.page,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 44,
              child: Align(
                alignment: Alignment.centerRight,
                child: _isLastPage
                    ? null
                    : Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: TextButton(
                          onPressed: _finish,
                          child: Text(
                            'Skip',
                            style: TextStyle(color: c.muted, fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                        ),
                      ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => _OnboardingPage(data: _pages[i], c: c),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) {
                final active = i == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: active ? PromptColors.accentGradient : null,
                    color: active ? null : c.line,
                  ),
                );
              }),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: _isLastPage
                  ? _GetStartedButton(onTap: _next)
                  : Align(alignment: Alignment.centerRight, child: _NextButton(onTap: _next)),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final _OnboardingPageData data;
  final PromptColors c;

  const _OnboardingPage({required this.data, required this.c});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            key: ValueKey(data.title),
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutCubic,
            builder: (context, t, child) {
              return Opacity(
                opacity: t,
                child: Transform.translate(offset: Offset(0, (1 - t) * 24), child: child),
              );
            },
            child: Container(
              width: 168,
              height: 168,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [c.accentSoft, c.page],
                ),
                border: Border.all(color: c.line, width: 1),
              ),
              child: Center(
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    gradient: PromptColors.accentGradient,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [PromptColors.cardShadow],
                  ),
                  child: Icon(data.icon, color: Colors.white, size: 40),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              height: 1.25,
              color: c.ink,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            data.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, height: 1.4, color: c.muted),
          ),
        ],
      ),
    );
  }
}

class _NextButton extends StatelessWidget {
  final VoidCallback onTap;

  const _NextButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: PromptColors.accentGradient,
          shape: BoxShape.circle,
          boxShadow: [PromptColors.cardShadow],
        ),
        child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 24),
      ),
    );
  }
}

class _GetStartedButton extends StatelessWidget {
  final VoidCallback onTap;

  const _GetStartedButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: PromptColors.accentGradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [PromptColors.cardShadow],
        ),
        child: const Center(
          child: Text(
            'Get Started',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
