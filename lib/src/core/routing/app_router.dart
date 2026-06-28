import 'package:flutter/cupertino.dart';
import 'package:flutter_app_template/src/core/routing/app_shell.dart';
import 'package:flutter_app_template/src/core/routing/tabs/create_tab.dart';
import 'package:flutter_app_template/src/core/routing/tabs/history_tab.dart';
import 'package:flutter_app_template/src/core/routing/tabs/profile_tab.dart';
import 'package:flutter_app_template/src/core/services/purchases/revenue_cat_service.dart';
import 'package:flutter_app_template/src/features/dev/presentation/views/dev_mode_view.dart';
import 'package:flutter_app_template/src/features/image_to_prompt/create/presentation/views/create_view.dart';
import 'package:flutter_app_template/src/features/image_to_prompt/history/presentation/views/history_detail_view.dart';
import 'package:flutter_app_template/src/features/image_to_prompt/models/history_entry_model.dart';
import 'package:flutter_app_template/src/features/image_to_prompt/settings/presentation/views/settings_view.dart';
import 'package:flutter_app_template/src/features/languages/presentation/pages/language_page.dart';
import 'package:flutter_app_template/src/features/onboarding/presentation/views/onboarding_view.dart';
import 'package:flutter_app_template/src/features/paywall/presentation/views/paywall_page.dart';
import 'package:flutter_app_template/src/features/theme/presentation/pages/theme_page.dart';
import 'package:go_router/go_router.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

class AppRouter {
  static const String baseRoute = '/';
  static const String defaultRoute = CreateView.routeName;

  GoRouter createRouter() {
    return GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: baseRoute,
      redirect: (context, state) => state.uri.path == baseRoute
          ? () {
              if (OnboardingView.isOnboardingCompleted()) {
                return AppRouter.defaultRoute;
              }
              return OnboardingView.routeName;
            }()
          : null,
      routes: [
        _statefulShellRoute(),
        ..._otherRoutes(),
      ],
    );
  }

  StatefulShellRoute _statefulShellRoute() {
    return StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => ImageToPromptShell(navigationShell: navigationShell),
      branches: [
        createTabBranch,
        historyTabBranch,
        profileTabBranch,
      ],
    );
  }

  List<RouteBase> _otherRoutes() {
    return [
      GoRoute(
        path: OnboardingView.routeName,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => CupertinoPage(child: const OnboardingView()),
      ),
      GoRoute(
        path: DevModeView.routeName,
        pageBuilder: (context, state) => CupertinoPage(child: DevModeView()),
      ),
      GoRoute(
        path: ThemePage.routeName,
        pageBuilder: (context, state) => CupertinoPage(child: ThemePage()),
      ),
      GoRoute(
        path: LanguagePage.routeName,
        pageBuilder: (context, state) => CupertinoPage(child: LanguagePage()),
      ),
      GoRoute(
        path: SettingsView.routeName,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => const CupertinoPage(child: SettingsView()),
      ),
      GoRoute(
        path: HistoryDetailView.routeName,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) =>
            CupertinoPage(child: HistoryDetailView(entry: state.extra as HistoryEntryModel)),
      ),
      GoRoute(
        path: PaywallPage.routeName,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          final paywallOffer = state.extra as PaywallOffers? ?? PaywallOffers.first_offer;
          return CupertinoPage(child: PaywallPage(paywallOffer: paywallOffer));
        },
      ),
    ];
  }
}
