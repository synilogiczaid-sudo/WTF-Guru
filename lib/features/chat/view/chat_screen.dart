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
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
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
      backgroundColor: AppColors.bgSoft,
      appBar: _ChatAppBar(
        peerName: pair.peerName,
        peerInitial: pair.peerName.isNotEmpty
            ? pair.peerName.characters.first.toUpperCase()
            : 'T',
        subtitleColor: AppColors.success,
        subtitle: 'Trainer • Online',
        onBack: () => context.go('/home'),
      ),
      body: SafeArea(
        top: false,
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
                      title: 'No messages yet',
                      subtitle:
                          'Say hi to ${pair.peerName} or pick a quick reply below to get going.',
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

class _ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ChatAppBar({
    required this.peerName,
    required this.peerInitial,
    required this.subtitle,
    required this.subtitleColor,
    required this.onBack,
  });

  final String peerName;
  final String peerInitial;
  final String subtitle;
  final Color subtitleColor;
  final VoidCallback onBack;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 64,
      titleSpacing: 0,
      leadingWidth: 44,
      leading: IconButton(
        onPressed: onBack,
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      title: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.trainerPrimary,
                      AppColors.trainerPrimary.withValues(alpha: 0.78),
                    ],
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  peerInitial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  peerName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                    letterSpacing: -0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: subtitleColor,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: const [
        _CallToolbarButton(),
        SizedBox(width: 4),
      ],
    );
  }
}

class _CallToolbarButton extends ConsumerWidget {
  const _CallToolbarButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final next = ref.watch(_upcomingCallProvider).valueOrNull;
    if (next == null) return const SizedBox.shrink();
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Material(
        color: primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.md),
          onTap: () => context.go('/home/prejoin/${next.id}'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(Icons.videocam_rounded, color: primary, size: 22),
                Positioned(
                  right: -4,
                  top: -3,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
