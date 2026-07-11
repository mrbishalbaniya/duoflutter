import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/config/app_config.dart';
import '../../core/models/chat_models.dart';
import '../../core/network/api_exception.dart';
import '../../core/providers/core_providers.dart';

class ChatThreadScreen extends ConsumerStatefulWidget {
  const ChatThreadScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends ConsumerState<ChatThreadScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  Conversation? _conversation;
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final chat = ref.read(chatRepositoryProvider);
      final results = await Future.wait([
        chat.getConversation(widget.conversationId),
        chat.getMessages(widget.conversationId),
      ]);
      setState(() {
        _conversation = results[0] as Conversation;
        _messages = (results[1] as List<ChatMessage>).reversed.toList();
        _loading = false;
      });
      await _connectWebSocket();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _connectWebSocket() async {
    final tokenStorage = ref.read(tokenStorageProvider);
    final access = await tokenStorage.getAccessToken();
    if (access == null) return;

    final ticket = await ref.read(chatRepositoryProvider).getWsTicket(widget.conversationId);
    final uri = Uri.parse(
      '${AppConfig.wsBaseUrl}/ws/chat/${widget.conversationId}/?ticket=$ticket',
    );

    _channel = WebSocketChannel.connect(uri);
    _subscription = _channel!.stream.listen((event) {
      final data = jsonDecode(event as String) as Map<String, dynamic>;
      final type = data['type'] as String?;
      if (type == 'chat_message') {
        final msg = ChatMessage.fromJson(data);
        setState(() => _messages.add(msg));
        _scrollToBottom();
      } else if (type == 'typing_status') {
        // UI typing indicator can be wired here
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _controller.clear();

    try {
      if (_channel != null) {
        _channel!.sink.add(jsonEncode({
          'type': 'chat_message',
          'content': text,
        }));
      } else {
        final msg = await ref.read(chatRepositoryProvider).sendMessage(
              widget.conversationId,
              content: text,
            );
        setState(() => _messages.add(msg));
        _scrollToBottom();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _subscription?.cancel();
    _channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_conversation?.displayName ?? 'Chat'),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (_, index) {
                      final msg = _messages[index];
                      final align = msg.isMine ? Alignment.centerRight : Alignment.centerLeft;
                      final color = msg.isMine
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surfaceContainerHighest;
                      final textColor =
                          msg.isMine ? Colors.white : Theme.of(context).colorScheme.onSurface;
                      return Align(
                        alignment: align,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.sizeOf(context).width * 0.75,
                          ),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(msg.content, style: TextStyle(color: textColor)),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Message…',
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _sending ? null : _send,
                    child: const Icon(Icons.send, size: 20),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
