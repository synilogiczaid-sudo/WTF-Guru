import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

import 'features/call/view/in_call_screen.dart';
import 'features/call/view/pre_join_screen.dart';
import 'features/chat/view/chat_screen.dart';
import 'features/home/view/home_screen.dart';
import 'features/onboarding/view/onboarding_screen.dart';
import 'features/onboarding/view/profile_setup_screen.dart';
import 'features/scheduler/view/schedule_call_screen.dart';
import 'features/sessions/view/sessions_screen.dart';

final GlobalKey<NavigatorState> guruRootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'guruRoot');

final guruRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authServiceProvider);
  return GoRouter(
    navigatorKey: guruRootNavigatorKey,
    initialLocation: auth.currentUser != null ? '/home' : '/onboarding',
    redirect: (context, state) {
      final user = ref.read(authServiceProvider).currentUser;
      final at = state.matchedLocation;
      final isAuthFlow = at.startsWith('/onboarding') || at == '/profile';
      if (user == null && !isAuthFlow) return '/onboarding';
      if (user != null && isAuthFlow) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (_, __) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (_, __) => const HomeScreen(),
        routes: [
          GoRoute(
            path: 'chat',
            builder: (_, __) => const ChatScreen(),
          ),
          GoRoute(
            path: 'schedule',
            builder: (_, __) => const ScheduleCallScreen(),
          ),
          GoRoute(
            path: 'sessions',
            builder: (_, __) => const SessionsScreen(),
          ),
          GoRoute(
            path: 'prejoin/:requestId',
            builder: (_, state) =>
                PreJoinScreen(requestId: state.pathParameters['requestId']!),
          ),
          GoRoute(
            path: 'call/:requestId',
            builder: (_, state) =>
                InCallScreen(requestId: state.pathParameters['requestId']!),
          ),
        ],
      ),
    ],
  );
});
