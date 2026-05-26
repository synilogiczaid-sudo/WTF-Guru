import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

import '../../../widgets/upcoming_call_banner.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  ScreenSync? _sync;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sync = ScreenSync(
        label: 'guru-home',
        tick: () => Future.wait([
          ref.read(callServiceProvider).refresh(),
          ref.read(chatServiceProvider).refreshActive(),
        ]),
      )..start();
    });
  }

  @override
  void dispose() {
    _sync?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.md,
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Hi, ${user.name.split(' ').first} 👋',
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 2),
                  const Text(
                    'Ready to train today?',
                    style: TextStyle(fontSize: 12, color: AppColors.subtle, fontWeight: FontWeight.normal),
                  ),
                ],
              ),
            ),
            const RoleBadge(role: 'Member', name: 'DK'),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const UpcomingCallBanner(),
              const SizedBox(height: AppSpacing.md),
              _Card(
                icon: Icons.forum_outlined,
                title: 'Chat with Trainer',
                subtitle: 'Drop a question, share a goal',
                onTap: () => context.go('/home/chat'),
              ),
              const SizedBox(height: AppSpacing.sm),
              _Card(
                icon: Icons.calendar_today_outlined,
                title: 'Schedule a Call',
                subtitle: 'Pick a slot in the next 3 days',
                onTap: () => context.go('/home/schedule'),
              ),
              const SizedBox(height: AppSpacing.sm),
              _Card(
                icon: Icons.history_rounded,
                title: 'My Sessions',
                subtitle: 'Past calls, ratings, and notes',
                onTap: () => context.go('/home/sessions'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.icon, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.primary;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Icon(icon, color: c),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.subtle)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.subtle),
            ],
          ),
        ),
      ),
    );
  }
}
