import 'package:flutter/material.dart';
import 'package:flutter_app_template/src/core/constants/hive_config.dart';
import 'package:flutter_app_template/src/core/routing/app_router.dart';
import 'package:flutter_app_template/src/features/image_to_prompt/presentation/prompt_colors.dart';
import 'package:flutter_app_template/src/features/onboarding/presentation/views/onboarding_view.dart';
import 'package:go_router/go_router.dart';

class SplashView extends StatefulWidget {
  static const String routeName = '/splash';

  static const _onboardingKey = 'onboardingCompleted';

  static Future<void> setOnboardingCompleted() async {
    await persistsData.put(_onboardingKey, true);
  }

  static bool isOnboardingCompleted() {
    return persistsData.get(_onboardingKey) == true;
  }

  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 700), vsync: this)..forward();
    _scale = Tween<double>(begin: 0.85, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _fade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 1100), () {
        if (!mounted) return;
        context.go(SplashView.isOnboardingCompleted() ? AppRouter.defaultRoute : OnboardingView.routeName);
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = PromptColors(settingsBox.get('itp_dark_mode', defaultValue: false) == true);
    return Scaffold(
      backgroundColor: c.page,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    gradient: PromptColors.accentGradient,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [PromptColors.cardShadow],
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 44),
                ),
                const SizedBox(height: 28),
                const SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(strokeWidth: 2.6, color: PromptColors.primary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
