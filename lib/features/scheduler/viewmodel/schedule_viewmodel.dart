import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

class ScheduleState {
  ScheduleState({this.slot, this.note = '', this.busy = false});
  final DateTime? slot;
  final String note;
  final bool busy;

  ScheduleState copyWith({DateTime? slot, String? note, bool? busy}) =>
      ScheduleState(slot: slot ?? this.slot, note: note ?? this.note, busy: busy ?? this.busy);
}

class ScheduleViewModel extends Notifier<ScheduleState> {
  @override
  ScheduleState build() => ScheduleState();

  void pickSlot(DateTime ts) => state = state.copyWith(slot: ts);
  void setNote(String text) => state = state.copyWith(note: text);

  Future<CallRequest> submit() async {
    final slot = state.slot;
    if (slot == null) throw ValidationError('Pick a time slot first.');
    Validators.ensureFutureSlot(slot);
    final note = Validators.ensureNote(state.note);

    final user = ref.read(currentUserProvider);
    if (user == null) throw StateError('Not signed in');

    state = state.copyWith(busy: true);
    try {
      final req = await ref.read(callServiceProvider).requestCall(
            memberId: user.id,
            trainerId: user.assignedTrainerId ?? 'trainer_aarav',
            scheduledFor: slot,
            note: note,
          );
      state = ScheduleState();
      return req;
    } finally {
      if (state.busy) state = state.copyWith(busy: false);
    }
  }
}

final scheduleViewModelProvider =
    NotifierProvider<ScheduleViewModel, ScheduleState>(ScheduleViewModel.new);

/// Member's request list for the "My Requests" section.
final myRequestsProvider = StreamProvider<List<CallRequest>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const []);
  return ref.watch(callServiceProvider).watchAll().map((all) =>
      all.where((r) => r.memberId == user.id).toList()
        ..sort((a, b) => b.requestedAt.compareTo(a.requestedAt)));
});
