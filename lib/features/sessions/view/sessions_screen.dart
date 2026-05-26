import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

import '../viewmodel/sessions_viewmodel.dart';

class SessionsScreen extends ConsumerStatefulWidget {
  const SessionsScreen({super.key});

  @override
  ConsumerState<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends ConsumerState<SessionsScreen> {
  ScreenSync? _sync;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sync = ScreenSync(
        label: 'sessions',
        tick: () => ref.read(logServiceProvider).refresh(),
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
    final filter = ref.watch(sessionsFilterProvider);
    final logs = ref.watch(mySessionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Sessions'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
              child: Wrap(
                spacing: 8,
                children: SessionsFilter.values.map((f) {
                  final selected = f == filter;
                  return ChoiceChip(
                    label: Text(f.label),
                    selected: selected,
                    onSelected: (_) => ref.read(sessionsFilterProvider.notifier).state = f,
                  );
                }).toList(),
              ),
            ),
            Expanded(
              child: logs.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const FriendlyError(title: "Couldn't load sessions"),
                data: (list) {
                  if (list.isEmpty) {
                    return EmptyState(
                      icon: Icons.timer_off_outlined,
                      title: 'No sessions yet',
                      subtitle: 'Once you finish your first call, the recap shows up here.',
                      action: PrimaryButton(
                        label: 'Schedule your first call',
                        onPressed: () => context.go('/home/schedule'),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (_, i) => _SessionTile(log: list[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.log});
  final SessionLog log;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: const Icon(Icons.videocam_rounded, color: AppColors.subtle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  TimeFormat.dateAndTime(log.startedAt),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  TimeFormat.duration(Duration(seconds: log.durationSec)),
                  style: const TextStyle(fontSize: 12, color: AppColors.subtle),
                ),
              ],
            ),
          ),
          if (log.rating != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, color: AppColors.warning, size: 18),
                const SizedBox(width: 2),
                Text('${log.rating}', style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w600)),
              ],
            ),
        ],
      ),
    );
  }
}
