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
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Pick a slot in the next 3 days',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.md),
                    SlotPicker(
                      selected: state.slot,
                      onPick: ref.read(scheduleViewModelProvider.notifier).pickSlot,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _note,
                      maxLength: 140,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Note for trainer',
                        hintText: 'e.g. Macros review, lower-back doubt…',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text('My requests', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    requests.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (_, __) => const Card(
                        child: Padding(
                          padding: EdgeInsets.all(AppSpacing.md),
                          child: Text(
                            "Couldn't load your requests. Pull down to refresh.",
                            style: TextStyle(color: AppColors.subtle, fontSize: 13),
                          ),
                        ),
                      ),
                      data: (list) {
                        if (list.isEmpty) {
                          return const Card(
                            child: Padding(
                              padding: EdgeInsets.all(AppSpacing.md),
                              child: Text(
                                'No requests yet. Pick a slot above to get started.',
                                style: TextStyle(color: AppColors.subtle),
                              ),
                            ),
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
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: const Border(top: BorderSide(color: AppColors.divider)),
              ),
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
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

class _RequestTile extends StatelessWidget {
  const _RequestTile(this.req);
  final CallRequest req;

  String get _statusLine => switch (req.status) {
        CallRequestStatus.pending => 'Pending approval by Aarav',
        CallRequestStatus.approved => 'Approved',
        CallRequestStatus.declined => 'Declined',
        CallRequestStatus.cancelled => 'Cancelled',
        CallRequestStatus.completed => 'Completed',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  TimeFormat.dateAndTime(req.scheduledFor),
                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink),
                ),
              ),
              _StatusChip(status: req.status),
            ],
          ),
          const SizedBox(height: 2),
          Text(_statusLine, style: const TextStyle(color: AppColors.subtle, fontSize: 12)),
          if (req.note.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(req.note, style: const TextStyle(color: AppColors.subtle, fontSize: 13)),
          ],
          if (req.status == CallRequestStatus.declined && req.declineReason != null) ...[
            const SizedBox(height: 6),
            Text(
              'Reason: ${req.declineReason!}',
              style: const TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final CallRequestStatus status;

  @override
  Widget build(BuildContext context) {
    late final Color bg;
    late final Color fg;
    late final String label;
    switch (status) {
      case CallRequestStatus.pending:
        bg = AppColors.warning.withValues(alpha: 0.15);
        fg = AppColors.warning;
        label = 'Pending';
      case CallRequestStatus.approved:
        bg = AppColors.success.withValues(alpha: 0.15);
        fg = AppColors.success;
        label = 'Approved';
      case CallRequestStatus.declined:
        bg = AppColors.error.withValues(alpha: 0.12);
        fg = AppColors.error;
        label = 'Declined';
      case CallRequestStatus.cancelled:
        bg = AppColors.subtle.withValues(alpha: 0.15);
        fg = AppColors.subtle;
        label = 'Cancelled';
      case CallRequestStatus.completed:
        bg = AppColors.subtle.withValues(alpha: 0.15);
        fg = AppColors.subtle;
        label = 'Completed';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadii.pill)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
