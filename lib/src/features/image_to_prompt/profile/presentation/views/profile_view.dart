import 'package:flutter/material.dart';
import 'package:flutter_app_template/src/core/services/locator/locator.dart';
import 'package:flutter_app_template/src/features/image_to_prompt/presentation/cubit/image_to_prompt_cubit.dart';
import 'package:flutter_app_template/src/features/image_to_prompt/presentation/prompt_colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfileView extends StatelessWidget {
  static const routeName = '/image-to-prompt/profile';
  const ProfileView({super.key});

  static const _stats = [
    ('248', 'PROMPTS'),
    ('37', 'SAVED'),
    ('∞', 'CREDITS'),
  ];

  static const _menuItems = [
    (icon: Icons.bookmark_outline, label: 'Saved Prompts'),
    (icon: Icons.workspace_premium_outlined, label: 'Subscription'),
    (icon: Icons.credit_card_outlined, label: 'Billing & Payment'),
    (icon: Icons.shield_outlined, label: 'Privacy & Security'),
    (icon: Icons.help_outline, label: 'Help & Support'),
  ];

  @override
  Widget build(BuildContext context) {
    final cubit = locator<ImageToPromptCubit>();
    return BlocBuilder<ImageToPromptCubit, ImageToPromptState>(
      bloc: cubit,
      builder: (context, state) {
        final c = PromptColors(state.darkMode);
        return ListView(
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
              children: List.generate(_stats.length, (i) {
                final s = _stats[i];
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i < _stats.length - 1 ? 12 : 0),
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
                  return Column(
                    children: [
                      if (i > 0) Divider(color: c.line, thickness: 1, height: 1),
                      InkWell(
                        onTap: () {},
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: c.iconBox,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(item.icon, color: c.accentText, size: 20),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Text(
                                  item.label,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: c.ink,
                                  ),
                                ),
                              ),
                              Icon(Icons.chevron_right, color: c.line, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }),
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
        );
      },
    );
  }
}
