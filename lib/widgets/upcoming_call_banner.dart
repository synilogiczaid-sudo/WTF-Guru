import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

/// Surfaces the next live or pending call for the signed-in member. We
/// drop anything past the joinable window even if the trainer never
/// explicitly closed it — otherwise the home banner offers "Join" on a
/// session nobody is going to attend.
final _myUpcomingCallsProvider = StreamProvider<List<CallRequest>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const []);
  return ref.watch(callServiceProvider).watchAll().map((all) {
    return all
        .where((r) =>
            r.memberId == user.id &&
            (r.status == CallRequestStatus.approved ||
                r.status == CallRequestStatus.pending) &&
            !r.isWindowExpired)
        .toList()
      ..sort((a, b) => a.scheduledFor.compareTo(b.scheduledFor));
  });
});

class UpcomingCallBanner extends ConsumerWidget {
  const UpcomingCallBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calls = ref.watch(_myUpcomingCallsProvider).valueOrNull ?? const <CallRequest>[];
    if (calls.isEmpty) return const SizedBox.shrink();
    final next = calls.first;
    final joinable = next.isJoinable;
    final pending = next.status == CallRequestStatus.pending;
    return Card(
      color: joinable ? Theme.of(context).colorScheme.primary : AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(
              joinable
                  ? Icons.videocam_rounded
                  : pending
                      ? Icons.hourglass_top_rounded
                      : Icons.event_rounded,
              color: joinable ? Colors.white : AppColors.subtle,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    joinable
                        ? 'Your call is ready'
                        : pending
                            ? 'Waiting for trainer'
                            : 'Upcoming call',
                    style: TextStyle(
                      color: joinable ? Colors.white : AppColors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    TimeFormat.dateAndTime(next.scheduledFor),
                    style: TextStyle(
                      color: joinable ? Colors.white.withValues(alpha: 0.85) : AppColors.subtle,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (joinable)
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                onPressed: () => context.go('/home/prejoin/${next.id}'),
                child: const Text('Join'),
              ),
            IconButton(
              tooltip: 'Dismiss',
              icon: Icon(
                Icons.close_rounded,
                color: joinable ? Colors.white : AppColors.subtle,
                size: 20,
              ),
              onPressed: () async {
                final svc = ref.read(callServiceProvider);
                await svc.markCompleted(next);
              },
            ),
          ],
        ),
      ),
    );
  }
}
