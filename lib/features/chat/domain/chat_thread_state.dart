import '../../../core/models/chat_models.dart';
import 'chat_message_list_entry.dart';

class ChatThreadState {
  const ChatThreadState({
    this.conversation,
    this.messages = const [],
    this.visibleMessages = const [],
    this.listEntries = const [],
    this.messagesByKey = const {},
    this.loading = true,
    this.loadingEarlier = false,
    this.sending = false,
    this.uploading = false,
    this.hasMore = true,
    this.isOtherUserTyping = false,
    this.showEmojiPicker = false,
    this.replyingTo,
    this.wsConnected = false,
    this.wsReconnecting = false,
    this.httpDeliveryOk = true,
    this.initialScrollPending = false,
    this.isRecording = false,
    this.voiceDraftReady = false,
    this.voiceRecordingSeconds = 0,
    this.micPermissionDenied = false,
    this.error,
  });

  final Conversation? conversation;
  final List<ChatMessage> messages;
  final List<ChatMessage> visibleMessages;
  final List<ChatMessageListEntry> listEntries;
  final Map<String, ChatMessage> messagesByKey;
  final bool loading;
  final bool loadingEarlier;
  final bool sending;
  final bool uploading;
  final bool hasMore;
  final bool isOtherUserTyping;
  final bool showEmojiPicker;
  final ChatMessage? replyingTo;
  final bool wsConnected;
  final bool wsReconnecting;
  final bool httpDeliveryOk;
  final bool initialScrollPending;
  final bool isRecording;
  final bool voiceDraftReady;
  final int voiceRecordingSeconds;
  final bool micPermissionDenied;
  final String? error;

  bool get isVoiceComposeActive => isRecording || voiceDraftReady;

  /// Next.js has no reconnect banner while HTTP fallback works.
  bool get showReconnectBanner =>
      wsReconnecting && !wsConnected && !httpDeliveryOk && !loading;

  ChatThreadState copyWith({
    Conversation? conversation,
    List<ChatMessage>? messages,
    List<ChatMessage>? visibleMessages,
    List<ChatMessageListEntry>? listEntries,
    Map<String, ChatMessage>? messagesByKey,
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
    bool? wsReconnecting,
    bool? httpDeliveryOk,
    bool? initialScrollPending,
    bool? isRecording,
    bool? voiceDraftReady,
    int? voiceRecordingSeconds,
    bool? micPermissionDenied,
    String? error,
    bool clearError = false,
  }) {
    return ChatThreadState(
      conversation: conversation ?? this.conversation,
      messages: messages ?? this.messages,
      visibleMessages: visibleMessages ?? this.visibleMessages,
      listEntries: listEntries ?? this.listEntries,
      messagesByKey: messagesByKey ?? this.messagesByKey,
      loading: loading ?? this.loading,
      loadingEarlier: loadingEarlier ?? this.loadingEarlier,
      sending: sending ?? this.sending,
      uploading: uploading ?? this.uploading,
      hasMore: hasMore ?? this.hasMore,
      isOtherUserTyping: isOtherUserTyping ?? this.isOtherUserTyping,
      showEmojiPicker: showEmojiPicker ?? this.showEmojiPicker,
      replyingTo: clearReplyingTo ? null : (replyingTo ?? this.replyingTo),
      wsConnected: wsConnected ?? this.wsConnected,
      wsReconnecting: wsReconnecting ?? this.wsReconnecting,
      httpDeliveryOk: httpDeliveryOk ?? this.httpDeliveryOk,
      initialScrollPending: initialScrollPending ?? this.initialScrollPending,
      isRecording: isRecording ?? this.isRecording,
      voiceDraftReady: voiceDraftReady ?? this.voiceDraftReady,
      voiceRecordingSeconds: voiceRecordingSeconds ?? this.voiceRecordingSeconds,
      micPermissionDenied: micPermissionDenied ?? this.micPermissionDenied,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
