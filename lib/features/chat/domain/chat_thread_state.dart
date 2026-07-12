import '../../../core/models/chat_models.dart';

class ChatThreadState {
  const ChatThreadState({
    this.conversation,
    this.messages = const [],
    this.loading = true,
    this.loadingEarlier = false,
    this.sending = false,
    this.uploading = false,
    this.hasMore = true,
    this.isOtherUserTyping = false,
    this.showEmojiPicker = false,
    this.replyingTo,
    this.wsConnected = false,
    this.initialScrollPending = false,
    this.error,
  });

  final Conversation? conversation;
  final List<ChatMessage> messages;
  final bool loading;
  final bool loadingEarlier;
  final bool sending;
  final bool uploading;
  final bool hasMore;
  final bool isOtherUserTyping;
  final bool showEmojiPicker;
  final ChatMessage? replyingTo;
  final bool wsConnected;
  final bool initialScrollPending;
  final String? error;

  List<ChatMessage> get visibleMessages =>
      messages.where((m) => m.isVisible).toList();

  ChatThreadState copyWith({
    Conversation? conversation,
    List<ChatMessage>? messages,
    bool? loading,
    bool? loadingEarlier,
    bool? sending,
    bool? uploading,
    bool? hasMore,
    bool? isOtherUserTyping,
    bool? showEmojiPicker,
    ChatMessage? replyingTo,
    bool clearReplyingTo = false,
    bool? wsConnected,
    bool? initialScrollPending,
    String? error,
    bool clearError = false,
  }) {
    return ChatThreadState(
      conversation: conversation ?? this.conversation,
      messages: messages ?? this.messages,
      loading: loading ?? this.loading,
      loadingEarlier: loadingEarlier ?? this.loadingEarlier,
      sending: sending ?? this.sending,
      uploading: uploading ?? this.uploading,
      hasMore: hasMore ?? this.hasMore,
      isOtherUserTyping: isOtherUserTyping ?? this.isOtherUserTyping,
      showEmojiPicker: showEmojiPicker ?? this.showEmojiPicker,
      replyingTo: clearReplyingTo ? null : (replyingTo ?? this.replyingTo),
      wsConnected: wsConnected ?? this.wsConnected,
      initialScrollPending: initialScrollPending ?? this.initialScrollPending,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
