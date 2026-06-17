import 'package:flutter/cupertino.dart';
import 'package:flutter_app_template/src/features/image_to_prompt/create/presentation/views/create_view.dart';
import 'package:go_router/go_router.dart';

final createTabBranch = StatefulShellBranch(
  routes: [
    GoRoute(
      path: CreateView.routeName,
      pageBuilder: (context, state) => const CupertinoPage(child: CreateView()),
    ),
  ],
);
