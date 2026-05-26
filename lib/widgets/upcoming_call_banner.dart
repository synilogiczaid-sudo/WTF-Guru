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
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOut,
      child: joinable
          ? _JoinableBanner(
              key: ValueKey('joinable-${next.id}'),
              call: next,
              onDismiss: () => ref.read(callServiceProvider).markCompleted(next),
            )
          : _UpcomingBanner(
              key: ValueKey('upcoming-${next.id}-$pending'),
              call: next,
              pending: pending,
              onDismiss: () => ref.read(callServiceProvider).markCompleted(next),
            ),
    );
  }
}

class _JoinableBanner extends StatelessWidget {
  const _JoinableBanner({super.key, required this.call, required this.onDismiss});
  final CallRequest call;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.sm, AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.success,
            Color.lerp(AppColors.success, AppColors.ink, 0.35)!,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.30),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.32)),
            ),
            child: const Icon(Icons.videocam_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    _LivePulse(),
                    SizedBox(width: 6),
                    Text(
                      'Your call is ready',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  TimeFormat.dateAndTime(call.scheduledFor),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          FilledButton(
            onPressed: () => context.go('/home/prejoin/${call.id}'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: primary,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              minimumSize: const Size(0, 38),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.pill)),
              textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            child: const Text('Join'),
          ),
          IconButton(
            tooltip: 'Dismiss',
            icon: Icon(Icons.close_rounded, color: Colors.white.withValues(alpha: 0.85), size: 18),
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}

class _UpcomingBanner extends StatelessWidget {
  const _UpcomingBanner({
    super.key,
    required this.call,
    required this.pending,
    required this.onDismiss,
  });
  final CallRequest call;
  final bool pending;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final accent = pending ? AppColors.warning : primary;
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.sm, AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.divider),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A101828),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Icon(
              pending ? Icons.hourglass_top_rounded : Icons.event_rounded,
              color: accent,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pending ? 'Waiting for trainer' : 'Upcoming call',
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  TimeFormat.dateAndTime(call.scheduledFor),
                  style: const TextStyle(
                    color: AppColors.subtle,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Dismiss',
            icon: const Icon(Icons.close_rounded, color: AppColors.subtle, size: 18),
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}

class _LivePulse extends StatefulWidget {
  const _LivePulse();
  @override
  State<_LivePulse> createState() => _LivePulseState();
}

class _LivePulseState extends State<_LivePulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.4 + _c.value * 0.5),
                blurRadius: 6 + _c.value * 6,
              ),
            ],
          ),
        );
      },
    );
  }
}
