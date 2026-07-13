# Flutter Conversation Screen - Implementation Plan

## Status: Ready for Development
**Created**: July 12, 2026  
**Analysis Complete**: ✅ YES  
**Project Structure Created**: ✅ YES  

## Quick Start

Due to context limitations, this document provides the implementation roadmap. The complete analysis of the Next.js page is available in `CONVERSATION_PAGE_ANALYSIS.md`.

## Directory Structure Created

```
lib/
├── features/
│   └── chat/
│       ├── data/
│       │   ├── datasources/        # API & WebSocket clients
│       │   └── repositories/       # Repository implementations
│       ├── domain/
│       │   ├── entities/           # Business models (Freezed)
│       │   └── repositories/       # Repository interfaces
│       └── presentation/
│           ├── providers/          # Riverpod state management
│           ├── screens/            # Main chat screen
│           └── widgets/            # Reusable widgets
└── core/
    └── websocket/                  # WebSocket manager
```

## Implementation Steps

### Step 1: Update pubspec.yaml
Add these dependencies:
```yaml
dependencies:
  flutter_riverpod: ^2.5.0
  freezed_annotation: ^2.4.0
  json_annotation: ^4.8.0
  dio: ^5.4.0
  web_socket_channel: ^2.4.0
  cached_network_image: ^3.3.0
  image_picker: ^1.0.4
  camera: ^0.10.5
  permission_handler: ^11.0.0
  record: ^5.0.0
  audioplayers: ^5.2.0
  photo_view: ^0.14.0
  flutter_animate: ^4.3.0
  go_router: ^13.0.0
  intl: ^0.18.0
  uuid: ^4.2.0
  hive: ^2.2.3
  hive_flutter: ^1.1.0

dev_dependencies:
  build_runner: ^2.4.0
  freezed: ^2.4.0
  json_serializable: ^6.7.0
```

### Step 2: Create Domain Entities
Create the following files in `lib/features/chat/domain/entities/`:

1. **chat_message_entity.dart** - Message model with Freezed
2. **conversation_entity.dart** - Conversation model
3. **message_reply_entity.dart** - Reply preview model
4. **message_reaction_entity.dart** - Reaction model

### Step 3: Create Data Sources
Create in `lib/features/chat/data/datasources/`:

1. **chat_api_client.dart** - REST API client with Dio
2. **chat_websocket_client.dart** - WebSocket connection manager

### Step 4: Create Repositories
Create in `lib/features/chat/data/repositories/`:

1. **chat_repository_impl.dart** - Implementation of chat operations

### Step 5: Create Providers
Create in `lib/features/chat/presentation/providers/`:

1. **conversation_list_provider.dart** - Manage conversation list state
2. **chat_messages_provider.dart** - Manage messages for a conversation
3. **websocket_provider.dart** - WebSocket connection state
4. **chat_input_provider.dart** - Input composer state

### Step 6: Create Widgets
Create in `lib/features/chat/presentation/widgets/`:

1. **conversation_list_item.dart** - Single conversation row
2. **chat_message_bubble.dart** - Message bubble (sent/received)
3. **chat_input_composer.dart** - Message input with attachments
4. **chat_thread_header.dart** - Header with user info
5. **voice_message_player.dart** - Audio player widget
6. **image_lightbox.dart** - Fullscreen image viewer
7. **emoji_reaction_picker.dart** - Quick emoji picker
8. **typing_indicator.dart** - Animated typing dots
9. **date_separator.dart** - "Today", "Yesterday" separators
10. **message_status_indicator.dart** - Read/delivered/sent icons
11. **reply_quote_widget.dart** - Quoted message display
12. **camera_capture_widget.dart** - In-app camera

### Step 7: Create Main Screen
Create in `lib/features/chat/presentation/screens/`:

1. **conversation_screen.dart** - Main chat screen with:
   - Conversation list (sidebar on tablet)
   - Message thread view
   - Input composer
   - Real-time updates
   - Navigation logic

### Step 8: Core WebSocket Manager
Create in `lib/core/websocket/`:

1. **websocket_manager.dart** - Auto-reconnecting WebSocket with exponential backoff

## Key Features to Implement

### Must-Have Features (MVP)
- ✅ List conversations with search
- ✅ Display messages with pagination
- ✅ Send text messages
- ✅ Send image messages
- ✅ Real-time messaging via WebSocket
- ✅ Typing indicators
- ✅ Read receipts
- ✅ Delivery status
- ✅ Optimistic UI
- ✅ Auto-reconnect
- ✅ Reply to messages
- ✅ Delete messages
- ✅ Message grouping
- ✅ Date separators
- ✅ Avatar display
- ✅ Timestamp formatting

### Enhanced Features
- ✅ Emoji reactions
- ✅ Voice messages (record & play)
- ✅ Image lightbox
- ✅ Camera capture
- ✅ Pull to refresh
- ✅ Infinite scroll (older messages)
- ✅ Search conversations
- ✅ Archive/mute/pin conversations
- ✅ Edit nickname
- ✅ Block/report user
- ✅ Match insights
- ✅ Profile view

### Animations
- Message appear (slide + fade)
- Send button scale
- Typing indicator pulse
- Emoji reaction bounce
- Hero transitions (avatar)
- Page transitions
- Swipe gestures

## API Integration

### Base URL
Use existing API client from `lib/data/api_client.dart`

### Endpoints Required
```dart
// Conversations
GET  /chat/conversations/
GET  /chat/conversations/{id}/
POST /chat/conversations/{id}/messages/
GET  /chat/conversations/{id}/messages/?limit=50&before={id}
POST /chat/upload-image/
POST /chat/ws-ticket/{id}/

// Actions
PATCH /chat/conversations/{id}/nickname/
POST  /chat/conversations/{id}/archive/
POST  /chat/conversations/{id}/mute/
POST  /chat/conversations/{id}/pin/
DELETE /chat/conversations/{id}/
POST  /chat/report/
POST  /chat/block/
POST  /chat/unmatch/
```

### WebSocket
```
wss://{backend}/ws/chat/{conversation_id}/?ticket={ticket}
```

## State Management Pattern (Riverpod)

```dart
// Example provider structure
final conversationListProvider = FutureProvider<List<Conversation>>((ref) async {
  final repository = ref.read(chatRepositoryProvider);
  return repository.getConversations();
});

final messagesProvider = FutureProvider.family<List<ChatMessage>, int>((ref, conversationId) async {
  final repository = ref.read(chatRepositoryProvider);
  return repository.getMessages(conversationId);
});

final websocketProvider = StateNotifierProvider<WebSocketNotifier, WebSocketState>((ref) {
  return WebSocketNotifier();
});
```

## Testing Strategy

1. **Unit Tests**: Repository, providers, models
2. **Widget Tests**: Individual widgets
3. **Integration Tests**: Full conversation flow
4. **Golden Tests**: Visual regression testing

## Performance Targets

- 60 FPS scrolling
- < 100ms message send latency
- < 500ms cold start
- < 50MB memory footprint
- Smooth animations

## Next Steps

1. Run `flutter pub get` after updating pubspec.yaml
2. Run `flutter pub run build_runner build --delete-conflicting-outputs` to generate code
3. Implement entities with Freezed annotations
4. Create API client with Dio
5. Build WebSocket manager
6. Implement repository pattern
7. Create Riverpod providers
8. Build UI widgets
9. Assemble main screen
10. Test thoroughly

## References

- **Complete Analysis**: See `CONVERSATION_PAGE_ANALYSIS.md`
- **Next.js Source**: `DuoFrontend/components/message/`
- **Backend Models**: `DuoBackend/chat/models.py`
- **Existing Flutter Models**: `DuoMobile/lib/data/models/`

## Notes

The existing Flutter project already has some foundation:
- `message_model.dart` exists
- `conversation_model.dart` exists  
- `profile_model.dart` exists
- Basic API client exists

**Leverage existing code** and extend it with the new features documented in the analysis.

---

**Ready to start implementation!** 🚀

Begin with Step 1 (pubspec.yaml) and proceed sequentially through the steps.
