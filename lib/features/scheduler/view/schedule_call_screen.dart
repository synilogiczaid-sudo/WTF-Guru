import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

import '../viewmodel/schedule_viewmodel.dart';

class ScheduleCallScreen extends ConsumerStatefulWidget {
  const ScheduleCallScreen({super.key});

  @override
  ConsumerState<ScheduleCallScreen> createState() => _ScheduleCallScreenState();
}

class _ScheduleCallScreenState extends ConsumerState<ScheduleCallScreen> {
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final vm = ref.read(scheduleViewModelProvider.notifier);
    vm.setNote(_note.text);
    try {
      await vm.submit();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Call requested. Waiting for trainer approval.')),
      );
      _note.clear();
      // Jump back home so the new pending row + banner is what the
      // member sees, instead of leaving them on the form.
      context.go('/home');
    } on ValidationError catch (e) {
      if (!mounted) return;
      showErrorSnackbar(context, message: e.message);
    } catch (e, st) {
      if (!mounted) return;
      showErrorSnackbar(
        context,
        message: "Couldn't submit your request. Please try again.",
        error: e,
        stackTrace: st,
        tag: LogTag.schedule,
        logMessage: 'submit failed',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scheduleViewModelProvider);
    final requests = ref.watch(myRequestsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgSoft,
      appBar: AppBar(
        title: const Text('Schedule a call'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SectionCard(
                      title: 'Pick a slot',
                      subtitle: 'Next 3 days, 30 minute sessions',
                      icon: Icons.event_available_rounded,
                      child: SlotPicker(
                        selected: state.slot,
                        onPick: ref.read(scheduleViewModelProvider.notifier).pickSlot,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _SectionCard(
                      title: 'Note for trainer',
                      subtitle: 'Optional — give context for the call',
                      icon: Icons.chat_bubble_outline_rounded,
                      child: TextField(
                        controller: _note,
                        maxLength: 140,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Macros review, lower-back doubt…',
                          counterText: '',
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        'MY REQUESTS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.subtle,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    requests.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (_, __) => const _InfoCard(
                        icon: Icons.cloud_off_rounded,
                        text: "Couldn't load your requests. Pull down to refresh.",
                      ),
                      data: (list) {
                        if (list.isEmpty) {
                          return const _InfoCard(
                            icon: Icons.event_busy_rounded,
                            text: 'No requests yet. Pick a slot above to get started.',
                          );
                        }
                        return Column(
                          children: list.map(_RequestTile.new).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            // Sticky bottom CTA — content scrolls behind it. Sits above
            // the safe-area inset so it doesn't clip on devices with a
            // gesture bar.
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.divider)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0A101828),
                    blurRadius: 16,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.md),
              child: PrimaryButton(
                label: 'Request call',
                icon: Icons.event_available_outlined,
                onPressed: _submit,
                loading: state.busy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.divider),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08101828),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Icon(icon, color: primary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(fontSize: 12, color: AppColors.subtle)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Icon(icon, color: AppColors.subtle, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: const TextStyle(color: AppColors.subtle, fontSize: 13, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  const _RequestTile(this.req);
  final CallRequest req;

  String get _statusLine => switch (req.status) {
        CallRequestStatus.pending => 'Pending approval by Aarav',
        CallRequestStatus.approved => 'Approved — keep an eye out for the join button',
        CallRequestStatus.declined => 'Declined by trainer',
        CallRequestStatus.cancelled => 'Cancelled',
        CallRequestStatus.completed => 'Completed',
      };

  IconData get _statusIcon => switch (req.status) {
        CallRequestStatus.pending => Icons.hourglass_top_rounded,
        CallRequestStatus.approved => Icons.event_available_rounded,
        CallRequestStatus.declined => Icons.cancel_outlined,
        CallRequestStatus.cancelled => Icons.do_not_disturb_on_outlined,
        CallRequestStatus.completed => Icons.task_alt_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(req.status);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08101828),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Icon(_statusIcon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  TimeFormat.dateAndTime(req.scheduledFor),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                    fontSize: 14.5,
                  ),
                ),
              ),
              _StatusChip(status: req.status),
            ],
          ),
          const SizedBox(height: 10),
          Text(_statusLine, style: const TextStyle(color: AppColors.subtle, fontSize: 12.5)),
          if (req.note.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(color: AppColors.dividerSoft),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.format_quote_rounded,
                      color: AppColors.muted, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(req.note,
                        style: const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
                  ),
                ],
              ),
            ),
          ],
          if (req.status == CallRequestStatus.declined && req.declineReason != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Text(
                'Reason: ${req.declineReason!}',
                style: const TextStyle(color: AppColors.error, fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

Color _statusColor(CallRequestStatus s) => switch (s) {
      CallRequestStatus.pending => AppColors.warning,
      CallRequestStatus.approved => AppColors.success,
      CallRequestStatus.declined => AppColors.error,
      CallRequestStatus.cancelled => AppColors.subtle,
      CallRequestStatus.completed => AppColors.subtle,
    };

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final CallRequestStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    final label = switch (status) {
      CallRequestStatus.pending => 'Pending',
      CallRequestStatus.approved => 'Approved',
      CallRequestStatus.declined => 'Declined',
      CallRequestStatus.cancelled => 'Cancelled',
      CallRequestStatus.completed => 'Completed',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.2)),
        ],
      ),
    );
  }
}
