import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

/// On first frame after the user is known, push our profile into the
/// local user directory + best-effort to the optional relay so the
/// trainer roster on another device picks us up the next time it opens.
///
/// No timers, no polling — refresh happens on screen open and on user
/// actions, period.
class RealtimeInit extends ConsumerStatefulWidget {
  const RealtimeInit({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<RealtimeInit> createState() => _RealtimeInitState();
}

class _RealtimeInitState extends ConsumerState<RealtimeInit> {
  String? _bootedFor;

  void _boot(String userId) {
    _bootedFor = userId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authServiceProvider).syncSelf();
      final user = ref.read(currentUserProvider);
      if (user != null) {
        ref.read(userDirectoryProvider).upsert(user);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user != null && user.id != _bootedFor) {
      _boot(user.id);
    }
    return widget.child;
  }
}
