import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

import 'router.dart';
import 'widgets/realtime_init.dart';

class GuruApp extends ConsumerWidget {
  const GuruApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(guruRouterProvider);
    return RealtimeInit(
      child: MaterialApp.router(
        title: 'WTF Guru',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.build(AppFlavor.guru),
        routerConfig: router,
      ),
    );
  }
}
