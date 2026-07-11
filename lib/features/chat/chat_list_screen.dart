import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/chat_models.dart';
import '../../core/providers/core_providers.dart';

final conversationsProvider = FutureProvider.autoDispose<List<Conversation>>((ref) async {
  return ref.read(chatRepositoryProvider).getConversations();
});

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversations = ref.watch(conversationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(conversationsProvider),
          ),
        ],
      ),
      body: conversations.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No conversations yet'));
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, index) {
              final c = items[index];
              final photo = c.otherUserProfile.displayPhoto;
              final subtitle = c.lastMessage?.content ??
                  (c.isOtherUserTyping ? 'Typing…' : 'Say hello');
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage:
                      photo.isNotEmpty ? CachedNetworkImageProvider(photo) : null,
                  child: photo.isEmpty ? const Icon(Icons.person) : null,
                ),
                title: Text(c.displayName),
                subtitle: Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: c.unreadCount > 0
                    ? CircleAvatar(
                        radius: 12,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Text(
                          '${c.unreadCount}',
                          style: const TextStyle(color: Colors.white, fontSize: 11),
                        ),
                      )
                    : null,
                onTap: () => context.push('/chat/${c.publicId}'),
              );
            },
          );
        },
      ),
    );
  }
}
