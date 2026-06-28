import 'package:flutter/material.dart';
import 'package:flutter_app_template/src/core/gen/assets.gen.dart';
import 'package:flutter_app_template/src/core/routing/app_router.dart';
import 'package:flutter_app_template/src/core/constants/hive_config.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design palette (PromptGen onboarding — dark only).
class _Pg {
  static const bgTop = Color(0xFF1E1630);
  static const bgMid = Color(0xFF16111F);
  static const bgBottom = Color(0xFF14101C);
  static const purple = Color(0xFF7C3AED);
  static const purpleLight = Color(0xFFA855F7);
  static const violet = Color(0xFF8B5CF6);
  static const white = Color(0xFFFFFFFF);
  static const muted = Color(0xFF9CA3AF);
  static const dim = Color(0xFF7E768F);
  static const cardTop = Color(0xFF241E31);
  static const cardBottom = Color(0xFF221C2E);
  static const star = Color(0xFFFBBF24);
  static const dotIdle = Color(0xFF3A3348);

  static const bgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [bgTop, bgMid, bgBottom],
    stops: [0, 0.3, 1],
  );

  static const ctaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [purple, purpleLight],
  );

  static TextStyle font(
    double size,
    FontWeight weight, {
    Color color = white,
    double height = 1.2,
    double letterSpacing = 0,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );
}

class OnboardingView extends StatefulWidget {
  static const String routeName = '/onboarding';

  const OnboardingView({super.key});

  static const _onboardingKey = 'onboardingCompleted';

  static bool isOnboardingCompleted() {
    return persistsData.get(_onboardingKey) == true;
  }

  static Future<void> setOnboardingCompleted() async {
    await persistsData.put(_onboardingKey, true);
  }

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  // Top-level stages: 0 = welcome, 1 = carousel, 2 = reviews.
  final _stagePager = PageController();

  @override
  void dispose() {
    _stagePager.dispose();
    super.dispose();
  }

  void _goStage(int stage) {
    _stagePager.animateToPage(
      stage,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _finish() async {
    await OnboardingView.setOnboardingCompleted();
    if (!mounted) return;
    context.go(AppRouter.defaultRoute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: _Pg.bgGradient),
        child: SafeArea(
          child: PageView(
            controller: _stagePager,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _WelcomeStage(onGetStarted: () => _goStage(1)),
              _CarouselStage(onDone: () => _goStage(2)),
              _ReviewsStage(onContinue: _finish),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================= SHARED CTA =============================

class _GradientCta extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _GradientCta({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 19),
        decoration: BoxDecoration(
          gradient: _Pg.ctaGradient,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: _Pg.purple.withValues(alpha: 0.5),
              blurRadius: 34,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Center(
          child: Text(label, style: _Pg.font(18, FontWeight.w800, letterSpacing: 0.2)),
        ),
      ),
    );
  }
}

// ============================= SCREEN 1 — WELCOME =============================

class _WelcomeStage extends StatelessWidget {
  final VoidCallback onGetStarted;
  const _WelcomeStage({required this.onGetStarted});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // logo + glow
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            _Pg.violet.withValues(alpha: 0.55),
                            _Pg.purple.withValues(alpha: 0.18),
                            Colors.transparent,
                          ],
                          stops: const [0, 0.45, 0.7],
                        ),
                      ),
                    ),
                    Assets.images.appIconTransparent.image(width: 131),
                  ],
                ),
                const SizedBox(height: 48),
                Text(
                  'Turn any image into the perfect prompt',
                  textAlign: TextAlign.center,
                  style: _Pg.font(36, FontWeight.w800, height: 1.12, letterSpacing: -0.7),
                ),
                const SizedBox(height: 18),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: Text(
                    'Upload a visual and get a precise, ready-to-use AI prompt in seconds.',
                    textAlign: TextAlign.center,
                    style: _Pg.font(17, FontWeight.w500, color: _Pg.muted, height: 1.55),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 44),
          child: _GradientCta(label: 'Get Started', onTap: onGetStarted),
        ),
      ],
    );
  }
}

// ============================= SCREEN 2 — CAROUSEL =============================

class _CarouselSlide {
  final Widget graphic;
  final String title;
  final String subtitle;
  const _CarouselSlide({required this.graphic, required this.title, required this.subtitle});
}

class _CarouselStage extends StatefulWidget {
  final VoidCallback onDone;
  const _CarouselStage({required this.onDone});

  @override
  State<_CarouselStage> createState() => _CarouselStageState();
}

class _CarouselStageState extends State<_CarouselStage> {
  final _pager = PageController();
  int _slide = 0;

  static const _slides = [
    _CarouselSlide(
      graphic: _UploadGraphic(),
      title: 'Upload any image',
      subtitle: 'Drop a photo from your library or paste an image URL — we handle the rest.',
    ),
    _CarouselSlide(
      graphic: _ModelsGraphic(),
      title: 'Choose your style',
      subtitle: 'Pick Fast, Balanced, or Detailed AI models to match the depth you need.',
    ),
    _CarouselSlide(
      graphic: _PromptGraphic(),
      title: 'Get a precise prompt',
      subtitle: 'Copy, save, and reuse your generated prompts instantly, anytime.',
    ),
  ];

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  void _continue() {
    if (_slide < _slides.length - 1) {
      _pager.nextPage(duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
    } else {
      widget.onDone();
    }
  }

  void _goSlide(int i) {
    _pager.animateToPage(i, duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Expanded(
          child: PageView.builder(
            controller: _pager,
            itemCount: _slides.length,
            onPageChanged: (i) => setState(() => _slide = i),
            itemBuilder: (context, i) {
              final s = _slides[i];
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
                    child: SizedBox(height: 330, child: _GraphicStage(child: s.graphic)),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(36, 36, 36, 0),
                    child: Column(
                      children: [
                        Text(
                          s.title,
                          textAlign: TextAlign.center,
                          style: _Pg.font(30, FontWeight.w800, letterSpacing: -0.6),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          s.subtitle,
                          textAlign: TextAlign.center,
                          style: _Pg.font(16, FontWeight.w500, color: _Pg.muted, height: 1.55),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        // dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_slides.length, (i) {
            final active = i == _slide;
            return GestureDetector(
              onTap: () => _goSlide(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4.5),
                width: active ? 28 : 8,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  gradient: active ? _Pg.ctaGradient : null,
                  color: active ? null : _Pg.dotIdle,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 28),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 44),
          child: _GradientCta(label: 'Continue', onTap: _continue),
        ),
      ],
    );
  }
}

/// The purple rounded "stage" that holds each slide's graphic.
class _GraphicStage extends StatelessWidget {
  final Widget child;
  const _GraphicStage({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_Pg.violet, _Pg.purple],
        ),
        boxShadow: [
          BoxShadow(
            color: _Pg.purple.withValues(alpha: 0.4),
            blurRadius: 60,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            Positioned(
              top: -60,
              right: -50,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
            ),
            Positioned(
              bottom: -70,
              left: -40,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
            ),
            Positioned.fill(child: child),
          ],
        ),
      ),
    );
  }
}

class _UploadGraphic extends StatelessWidget {
  const _UploadGraphic();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          color: Colors.white.withValues(alpha: 0.06),
          border: Border.all(color: Colors.white.withValues(alpha: 0.55), width: 2.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.image_outlined, color: Colors.white, size: 64),
            const SizedBox(height: 18),
            Text('Drop or paste', style: _Pg.font(15, FontWeight.w800, letterSpacing: 0.3)),
          ],
        ),
      ),
    );
  }
}

class _ModelsGraphic extends StatelessWidget {
  const _ModelsGraphic();

  Widget _row(String label, {String? trailing, bool selected = false}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 22, vertical: selected ? 18 : 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: selected ? Colors.white : Colors.white.withValues(alpha: 0.12),
        boxShadow: selected
            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 30, offset: const Offset(0, 12))]
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: _Pg.font(
              selected ? 17 : 16,
              selected ? FontWeight.w800 : FontWeight.w700,
              color: selected ? _Pg.purple : _Pg.white,
            ),
          ),
          if (selected)
            const Icon(Icons.star_rounded, color: _Pg.purple, size: 22)
          else if (trailing != null)
            Text(trailing, style: _Pg.font(13, FontWeight.w600, color: Colors.white.withValues(alpha: 0.6))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _row('Fast', trailing: '~2s'),
          const SizedBox(height: 14),
          _row('Balanced', selected: true),
          const SizedBox(height: 14),
          _row('Detailed', trailing: '~8s'),
        ],
      ),
    );
  }
}

class _PromptGraphic extends StatelessWidget {
  const _PromptGraphic();

  Widget _bar(double widthFactor) {
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: Container(
        height: 9,
        decoration: BoxDecoration(
          color: const Color(0xFFE6DFF5),
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 34),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.28), blurRadius: 40, offset: const Offset(0, 18))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('GENERATED PROMPT', style: _Pg.font(11, FontWeight.w800, color: _Pg.purple, letterSpacing: 1.76)),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2EDFB),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.copy_rounded, color: _Pg.purple, size: 17),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _bar(1),
              const SizedBox(height: 9),
              _bar(0.9),
              const SizedBox(height: 9),
              _bar(0.64),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================= SCREEN 3 — SOCIAL PROOF =============================

class _Review {
  final String name;
  final String role;
  final String quote;
  final List<Color> avatar;
  const _Review({required this.name, required this.role, required this.quote, required this.avatar});
}

class _ReviewsStage extends StatelessWidget {
  final VoidCallback onContinue;
  const _ReviewsStage({required this.onContinue});

  static const _avatars = <(String, List<Color>)>[
    ('M', [Color(0xFFA855F7), Color(0xFF7C3AED)]),
    ('D', [Color(0xFF5B8DEF), Color(0xFF3F6BD6)]),
    ('P', [Color(0xFFF472B6), Color(0xFFDB4F8E)]),
    ('J', [Color(0xFF34D399), Color(0xFF10A877)]),
    ('A', [Color(0xFFFBBF24), Color(0xFFE89B11)]),
    ('S', [Color(0xFF22D3EE), Color(0xFF0FA5C0)]),
  ];

  static const _reviews = [
    _Review(
      name: 'Maya R.',
      role: 'Designer',
      quote: '"PromptGen nails the details every time. It\'s become essential to my workflow."',
      avatar: [Color(0xFFA855F7), Color(0xFF7C3AED)],
    ),
    _Review(
      name: 'Devin K.',
      role: 'Photographer',
      quote: '"I paste a screenshot and get a prompt that actually works. Pure magic."',
      avatar: [Color(0xFF5B8DEF), Color(0xFF3F6BD6)],
    ),
    _Review(
      name: 'Priya S.',
      role: 'Marketer',
      quote: '"The Detailed mode is unreal. Saves me hours of writing every single week."',
      avatar: [Color(0xFF34D399), Color(0xFF10A877)],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 8),
            child: Column(
              children: [
                Text(
                  'Loved by creators everywhere',
                  textAlign: TextAlign.center,
                  style: _Pg.font(34, FontWeight.w800, height: 1.12, letterSpacing: -0.68),
                ),
                const SizedBox(height: 26),
                const _AvatarCluster(),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const _Stars(size: 18),
                    const SizedBox(width: 10),
                    Text.rich(
                      TextSpan(
                        text: '4.9 ',
                        style: _Pg.font(15, FontWeight.w700),
                        children: [
                          TextSpan(text: '· 10k+ users', style: _Pg.font(15, FontWeight.w600, color: _Pg.dim)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                ..._reviews.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 13),
                      child: _ReviewCard(review: r),
                    )),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 44),
          child: _GradientCta(label: 'Continue', onTap: onContinue),
        ),
      ],
    );
  }
}

class _AvatarCluster extends StatelessWidget {
  const _AvatarCluster();

  @override
  Widget build(BuildContext context) {
    const avatars = _ReviewsStage._avatars;
    const overlap = 33.0;
    final totalWidth = avatars.length * overlap + 46;
    return SizedBox(
      height: 46,
      width: totalWidth,
      child: Stack(
        children: [
          for (var i = 0; i < avatars.length; i++)
            Positioned(
              left: i * overlap,
              child: _avatarCircle(avatars[i].$1, avatars[i].$2),
            ),
          Positioned(
            left: avatars.length * overlap,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2A2435),
                border: Border.all(color: _Pg.bgBottom, width: 2.5),
              ),
              alignment: Alignment.center,
              child: Text('+9k', style: _Pg.font(13, FontWeight.w800, color: const Color(0xFFC7BEE0))),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _avatarCircle(String letter, List<Color> colors) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
        border: Border.all(color: _Pg.bgBottom, width: 2.5),
      ),
      alignment: Alignment.center,
      child: Text(letter, style: _Pg.font(15, FontWeight.w800)),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final _Review review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_Pg.cardTop, _Pg.cardBottom],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: review.avatar,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(review.name[0], style: _Pg.font(15, FontWeight.w800)),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.name, style: _Pg.font(15, FontWeight.w700)),
                    Text(review.role, style: _Pg.font(12, FontWeight.w500, color: _Pg.dim)),
                  ],
                ),
              ),
              const _Stars(size: 13),
            ],
          ),
          const SizedBox(height: 11),
          Text(review.quote, style: _Pg.font(14.5, FontWeight.w500, color: _Pg.muted, height: 1.5)),
        ],
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  final double size;
  const _Stars({required this.size});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (_) => Icon(Icons.star_rounded, color: _Pg.star, size: size),
      ),
    );
  }
}
