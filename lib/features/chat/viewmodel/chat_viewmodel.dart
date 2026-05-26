import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

class ChatPair {
  ChatPair(this.user, this.peerId, this.peerName);
  final User user;
  final String peerId;
  final String peerName;

  String get chatId => Message.chatIdFor(user.id, peerId);
}

final chatPairProvider = Provider<ChatPair>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) throw StateError('chatPairProvider read without user');
  return ChatPair(user, user.assignedTrainerId ?? 'trainer_aarav', 'Aarav');
});

class ChatViewModel extends StreamNotifier<List<Message>> {
  @override
  Stream<List<Message>> build() {
    final pair = ref.watch(chatPairProvider);
    final svc = ref.watch(chatServiceProvider);
    _markReadSoon(pair.chatId);
    return svc.watchChat(pair.chatId);
  }

  void _markReadSoon(String chatId) {
    Future.microtask(() => ref.read(chatServiceProvider).markRead(chatId));
  }

  Future<void> send(String text) async {
    final pair = ref.read(chatPairProvider);
    await ref.read(chatServiceProvider).send(
          chatId: pair.chatId,
          receiverId: pair.peerId,
          text: text,
        );
  }

  void notifyTyping() {
    final pair = ref.read(chatPairProvider);
    ref.read(chatServiceProvider).sendTyping(pair.chatId, pair.peerId);
  }
}

final chatViewModelProvider =
    StreamNotifierProvider<ChatViewModel, List<Message>>(ChatViewModel.new);

final peerTypingProvider = StreamProvider<bool>((ref) {
  final pair = ref.watch(chatPairProvider);
  return ref.watch(chatServiceProvider).watchTyping(pair.chatId);
});
