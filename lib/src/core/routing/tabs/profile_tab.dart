import 'package:flutter/cupertino.dart';
import 'package:flutter_app_template/src/features/image_to_prompt/profile/presentation/views/profile_view.dart';
import 'package:go_router/go_router.dart';

final profileTabBranch = StatefulShellBranch(
  routes: [
    GoRoute(
      path: ProfileView.routeName,
      pageBuilder: (context, state) => const CupertinoPage(child: ProfileView()),
      routes: [],
    ),
  ],
);
