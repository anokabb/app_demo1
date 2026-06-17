import 'package:flutter/cupertino.dart';
import 'package:flutter_app_template/src/features/image_to_prompt/history/presentation/views/history_view.dart';
import 'package:go_router/go_router.dart';

final historyTabBranch = StatefulShellBranch(
  routes: [
    GoRoute(
      path: HistoryView.routeName,
      pageBuilder: (context, state) => const CupertinoPage(child: HistoryView()),
    ),
  ],
);
