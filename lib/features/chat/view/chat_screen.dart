import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

import '../viewmodel/chat_viewmodel.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _scroll = ScrollController();
  int _lastCount = 0;
  ScreenSync? _sync;

  @override
  void initState() {
    super.initState();
    // Lifecycle-scoped poller: refresh chat history every 2s while the
    // screen is mounted so a peer message lands "live" without a socket.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pair = ref.read(chatPairProvider);
      _sync = ScreenSync(
        label: 'chat:${pair.chatId}',
        tick: () => ref.read(chatServiceProvider).historyFor(pair.chatId),
      )..start();
    });
  }

  @override
  void dispose() {
    _sync?.stop();
    _scroll.dispose();
    super.dispose();
  }

  void _autoScroll(int count) {
    if (count == _lastCount) return;
    _lastCount = count;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final pair = ref.watch(chatPairProvider);
    final messages = ref.watch(chatViewModelProvider);
    final typing = ref.watch(peerTypingProvider).valueOrNull ?? false;
    final vm = ref.read(chatViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.go('/home'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.trainerPrimary.withValues(alpha: 0.15),
              child: const Text('A', style: TextStyle(color: AppColors.trainerPrimary, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(pair.peerName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink)),
                const Text('Trainer • Online',
                    style: TextStyle(fontSize: 11, color: AppColors.success)),
              ],
            ),
          ],
        ),
        actions: const [
          _CallToolbarButton(),
          SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: messages.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const FriendlyError(title: "Couldn't load chat"),
                data: (list) {
                  _autoScroll(list.length);
                  if (list.isEmpty) {
                    return EmptyState(
                      icon: Icons.chat_bubble_outline_rounded,
                      title: 'No messages yet. Start the conversation.',
                      subtitle: 'Say hi to ${pair.peerName} or pick a quick reply below.',
                      action: PrimaryButton(
                        label: 'Say hi',
                        icon: Icons.waving_hand_rounded,
                        onPressed: () => vm.send('Hi Coach 👋'),
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () =>
                        ref.read(chatServiceProvider).historyFor(pair.chatId),
                    child: ListView.builder(
                      controller: _scroll,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      itemCount: list.length + (typing ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (typing && i == list.length) return const TypingDots();
                        final m = list[i];
                        final isMe = m.senderId == pair.user.id;
                        final senderRole = isMe ? pair.user.role : UserRole.trainer;
                        return MessageBubble(message: m, senderRole: senderRole, isMe: isMe);
                      },
                    ),
                  );
                },
              ),
            ),
            ChatComposer(
              onSend: vm.send,
              onTyping: vm.notifyTyping,
            ),
          ],
        ),
      ),
    );
  }
}

class _CallToolbarButton extends ConsumerWidget {
  const _CallToolbarButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final next = ref.watch(_upcomingCallProvider).valueOrNull;
    if (next == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: IconButton(
        tooltip: 'Join upcoming call',
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.videocam_outlined),
            Positioned(
              right: -4,
              top: -2,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
              ),
            ),
          ],
        ),
        onPressed: () => context.go('/home/prejoin/${next.id}'),
      ),
    );
  }
}

/// Next joinable call (within 10 min window) for the toolbar icon.
final _upcomingCallProvider = StreamProvider<CallRequest?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);
  return ref.watch(callServiceProvider).watchAll().map((reqs) {
    final mine = reqs.where((r) => r.memberId == user.id && r.isJoinable).toList()
      ..sort((a, b) => a.scheduledFor.compareTo(b.scheduledFor));
    return mine.isEmpty ? null : mine.first;
  });
});
