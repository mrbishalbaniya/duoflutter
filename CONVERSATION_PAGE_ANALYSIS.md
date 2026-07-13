# Next.js Conversation Page - Complete Analysis

## Executive Summary
This document provides a comprehensive analysis of the Next.js conversation page (`/chat?conversation=id`) to guide the Flutter Android implementation.

## 1. Architecture Overview

### Next.js Page Structure
- **Route**: `/chat?conversation={id}`
- **Main Component**: `MessagesSection.tsx`
- **Layout**: Split-screen on desktop (1024px+), single-screen on mobile
- **State Management**: React hooks (useState, useEffect, useCallback, useRef)

### Key Components
1. **ChatSidebarNav** - Conversation list with search and filters
2. **MessagesSection** - Main chat thread view
3. **ChatThreadHeader** - Header with user info, typing status, actions
4. **ChatMessageBubble** - Individual message rendering
5. **ChatComposer** - Message input with attachments, voice, emoji

## 2. Data Models

### Conversation Model
```typescript
interface Conversation {
  id: number;
  public_id: string;        // 10-digit shareable ID
  match_id: number;
  match_created_at: string;
  other_user_nickname: string;
  other_user_profile: Profile;
  last_message: string | object;
  last_message_at: string;
  unread_count: number;
  is_archived: boolean;
  is_muted: boolean;
  is_pinned: boolean;
  is_other_user_typing: boolean;
}
```

### Message Model
```typescript
interface ChatMessage {
  id: number;
  sender_id: number;
  sender_name: string;
  sender_photo: string;
  content: string;
  image_url: string;
  message_type: 'text' | 'image' | 'voice';
  timestamp: string;
  delivered_at: string | null;
  read_at: string | null;
  edited_at: string | null;
  is_read: boolean;
  is_mine: boolean;
  is_deleted_for_me: boolean;
  is_deleted_for_everyone: boolean;
  reply_to: MessageReplyPreview | null;
  reactions: Record<string, number[]>;  // emoji -> [userIds]
  client_temp_id: string;
  send_status: 'pending' | 'sent' | 'failed';
}
```

### Reply Preview Model
```typescript
interface MessageReplyPreview {
  id: number;
  content: string;
  sender_name: string;
  image_url: string;
  message_type: string;
}
```

## 3. API Endpoints

### REST API
- `GET /chat/conversations/` - List all conversations
- `GET /chat/conversations/{id}/messages/?limit=50&before={id}` - Get paginated messages
- `POST /chat/conversations/{id}/messages/` - Send message
- `POST /chat/upload-image/` - Upload image/voice file
- `GET /chat/conversations/{id}/` - Get conversation detail
- `POST /chat/ws-ticket/{id}/` - Get WebSocket ticket
- `PATCH /chat/conversations/{id}/nickname/` - Update nickname
- `POST /chat/conversations/{id}/archive/` - Archive conversation
- `POST /chat/conversations/{id}/mute/` - Mute conversation
- `POST /chat/conversations/{id}/pin/` - Pin conversation
- `DELETE /chat/conversations/{id}/` - Delete conversation
- `POST /chat/report/` - Report user
- `POST /chat/block/` - Block user
- `POST /chat/unmatch/` - Unmatch user
- `DELETE /chat/messages/{id}/clear/` - Clear messages

## 4. WebSocket Protocol

### Connection
- **URL**: `wss://{backend}/ws/chat/{conversation_id}/?ticket={ticket}`
- **Authentication**: Ticket-based (obtained from REST API)
- **Auto-reconnect**: Exponential backoff (1s -> 15s max)

### Client -> Server Messages

#### Send Message
```json
{
  "type": "chat_message",
  "content": "Hello",
  "image_url": "",
  "reply_to_id": 123,
  "client_temp_id": "temp-uuid"
}
```

#### Typing Indicator
```json
{
  "type": "typing",
  "is_typing": true
}
```

#### Mark Messages Read
```json
{
  "type": "mark_read"
}
```

#### React to Message
```json
{
  "type": "message_reaction",
  "id": 456,
  "emoji": "❤️"
}
```

#### Delete Message
```json
{
  "type": "delete_message",
  "id": 456,
  "delete_type": "for_me" | "for_everyone"
}
```

### Server -> Client Messages

#### New Message
```json
{
  "type": "chat_message",
  "id": 789,
  "content": "Hello back",
  "image_url": "",
  "sender_name": "John Doe",
  "sender_id": 2,
  "timestamp": "2026-07-12T10:30:00Z",
  "message_type": "text",
  "reply_to": {...},
  "client_temp_id": "temp-uuid"
}
```

#### Typing Status
```json
{
  "type": "typing_status",
  "user_id": 2,
  "is_typing": true
}
```

#### Messages Read
```json
{
  "type": "messages_read",
  "reader_id": 2,
  "message_ids": [123, 456, 789]
}
```

#### Message Reacted
```json
{
  "type": "message_reacted",
  "id": 456,
  "user_id": 2,
  "emoji": "❤️",
  "reactions": {"❤️": [2], "👍": [1]}
}
```

#### Message Deleted
```json
{
  "type": "message_deleted",
  "id": 456,
  "user_id": 2,
  "delete_type": "for_everyone"
}
```

## 5. Features Inventory

### Conversation List (Sidebar)
- ✅ List all conversations sorted by activity
- ✅ Unread message count badges
- ✅ Search conversations by name/content
- ✅ Filter: Unread only
- ✅ Filter: Show archived
- ✅ Pin conversations (appear at top)
- ✅ Mute conversations
- ✅ Archive conversations
- ✅ Delete conversations
- ✅ Real-time typing indicators
- ✅ Last message preview
- ✅ Timestamp formatting (now, 5m, 2h, 3d, Jan 5)
- ✅ Pull to refresh
- ✅ Online presence indicator
- ✅ Verified badge display

### Chat Thread Header
- ✅ User avatar with Hero animation
- ✅ User name (or nickname)
- ✅ Verification badge
- ✅ Premium badge
- ✅ Online indicator
- ✅ Last seen / Matched {time} ago
- ✅ Typing indicator ("Typing…")
- ✅ Back button (mobile)
- ✅ Match insights button
- ✅ More options menu:
  - View profile
  - Edit nickname
  - Unmatch & Block
  - Clear conversation history
  - Report user

### Message List
- ✅ Infinite scroll (load older messages)
- ✅ Date separators (Today, Yesterday, etc.)
- ✅ Message grouping (5-minute window, same sender)
- ✅ Avatar display (only on last message in group)
- ✅ Bubble styling:
  - Sent: Gradient background, right-aligned
  - Received: Secondary background, left-aligned
- ✅ Message types:
  - Text messages
  - Image messages
  - Voice messages (WebM/Ogg/MP3)
  - Image + text combination
- ✅ Reply preview display
- ✅ Timestamp display
- ✅ Status indicators:
  - Pending (⏳)
  - Sent (✓)
  - Delivered (✓✓)
  - Read (✓✓ blue)
  - Failed (❌ with retry)
- ✅ Deleted message states:
  - "This message was deleted" (for_everyone)
  - Hidden from list (for_me)
- ✅ Emoji reactions display
- ✅ Auto-scroll to bottom on new message
- ✅ "START OF CONVERSATION" pill
- ✅ Empty state: "Say hello to start the conversation"
- ✅ Long press / right-click menu:
  - Copy text
  - Reply to message
  - React with emoji
  - Delete for me
  - Delete for everyone (own messages)

### Message Input (Composer)
- ✅ Auto-expanding text field
- ✅ Emoji picker (quick reactions)
- ✅ Send button (disabled when empty)
- ✅ Attachment options (expandable):
  - Camera capture
  - Gallery image picker
  - Voice recording
- ✅ Reply mode:
  - Shows quoted message
  - Cancel reply button
- ✅ Voice recording:
  - Tap to start recording
  - Waveform visualization
  - Cancel or send recording
- ✅ Camera capture:
  - Fullscreen camera view
  - Switch front/back camera
  - Capture photo
  - Auto-upload
- ✅ Image preview before send
- ✅ Upload progress indicator
- ✅ Typing indicator sent to server
- ✅ Focus management on mobile

### Real-Time Features
- ✅ Live messaging via WebSocket
- ✅ Optimistic UI (instant local message display)
- ✅ Server echo (replace temp message with real ID)
- ✅ Typing indicators (3-second timeout)
- ✅ Online presence updates
- ✅ Read receipts (real-time)
- ✅ Delivery receipts (real-time)
- ✅ Reaction updates (real-time)
- ✅ Auto-reconnect on disconnect
- ✅ Offline message queue (pending messages retry)
- ✅ Mark messages delivered on connect
- ✅ Mark messages read when viewing
- ✅ Fallback polling (when WebSocket unavailable)

### Media Handling
- ✅ Image lightbox / fullscreen viewer
  - Pinch to zoom
  - Swipe to dismiss
  - Download option
- ✅ Voice message player
  - Waveform visualization
  - Play/pause controls
  - Duration display
  - Playback progress
- ✅ Image upload with compression
- ✅ Voice recording (WebM format)
- ✅ Image caching (CDN URLs)

### Search & Filtering
- ✅ Search within conversation (future feature)
- ✅ Highlight matching messages (future feature)
- ✅ Previous/Next result navigation (future feature)

### Additional Features
- ✅ Match insights panel (compatibility scores)
- ✅ Profile detail sheet (view full profile)
- ✅ Nickname editing
- ✅ Conversation preferences:
  - Archive/unarchive
  - Mute/unmute
  - Pin/unpin
- ✅ Block user
- ✅ Report user
- ✅ Unmatch user
- ✅ Clear conversation history
- ✅ Toast notifications for actions

## 6. UX Patterns

### Message Bubbles
- **Sent (mine)**: Gradient pink/coral, rounded-[1.25rem] rounded-br-[0.2rem], right-aligned
- **Received (theirs)**: bg-secondary, rounded-[1.25rem] rounded-bl-[0.2rem], left-aligned
- **Compact**: Text-only and voice-only messages use smaller padding
- **Image-only**: No background, full-width image
- **Failed**: Red border ring with retry button

### Animations
- Message appearance: Slide up + fade in
- Typing indicator: Pulsing dots
- Emoji reactions: Scale bounce on add
- Camera capture: Fullscreen slide from bottom
- Emoji picker: Slide up from bottom
- Attachment options: Slide in from left
- Mobile thread: Slide from right

### Touch Interactions
- Long press message: Show action menu
- Swipe message right: Quick reply
- Pull down: Load older messages
- Pull down (list): Refresh conversations
- Tap avatar: View profile
- Tap image: Open lightbox
- Keep composer focus: Prevent blur on tool button tap

### Loading States
- Conversation list: Skeleton loader
- Messages: Skeleton bubbles
- Older messages: Top loading indicator
- Sending message: Pending status icon
- Uploading image: Hourglass icon

### Empty States
- No conversations: "No conversations yet / Start swiping to find matches!"
- No messages: "Say hello to start the conversation."
- Search no results: "No matches for your search."
- Start of thread: "START OF CONVERSATION" pill

## 7. Performance Optimizations

### Next.js Implementation
- Message caching (in-memory Map)
- Memoized computations (useMemo)
- Ref-based state for high-frequency updates
- Debounced typing indicators
- Lazy loading of older messages
- Optimistic UI for instant feedback
- WebSocket auto-reconnect with exponential backoff
- Fallback polling when WebSocket unavailable

### Expected Flutter Optimizations
- Const widgets where possible
- ListView.builder for message list
- CachedNetworkImage for avatars/images
- Debouncing for typing indicators
- Pagination with lazy loading
- Riverpod for efficient state management
- Freezed for immutable models
- WebSocket with auto-reconnect
- Local caching with Hive/SQLite
- Hero animations for avatar transitions

## 8. Technical Constraints

### Browser/Platform Features Used
- WebSocket (wss://)
- MediaRecorder API (voice recording)
- getUserMedia API (camera capture)
- File input (gallery picker)
- localStorage (caching)
- IntersectionObserver (auto-scroll detection)
- ResizeObserver (keyboard adjustment)

### Mobile Considerations
- Safe area insets (iOS notch)
- Keyboard avoiding behavior
- Touch-optimized tap targets (44x44 minimum)
- Haptic feedback (not in web, add to Flutter)
- Pull to refresh
- Swipe gestures
- Portrait-only orientation
- Dark mode support

## 9. Flutter Migration Strategy

### Phase 1: Core Architecture
1. Setup Riverpod state management
2. Create data models with Freezed
3. Setup Dio HTTP client
4. Setup WebSocket connection layer
5. Create repository pattern
6. Setup routing with GoRouter

### Phase 2: UI Foundation
7. Create conversation list screen
8. Create chat thread screen
9. Create message bubble widgets
10. Create input composer widget
11. Implement Material 3 theming

### Phase 3: Real-Time
12. Integrate WebSocket message handling
13. Implement optimistic UI
14. Add typing indicators
15. Add read receipts
16. Add delivery status
17. Auto-reconnect logic

### Phase 4: Media & Attachments
18. Image picker integration
19. Camera integration
20. Voice recorder
21. Image lightbox viewer
22. Voice message player

### Phase 5: Advanced Features
23. Emoji reactions
24. Reply system
25. Message deletion
26. Search in conversation
27. Pagination with infinite scroll
28. Pull to refresh

### Phase 6: Polish
29. Animations (Flutter Animate)
30. Hero transitions
31. Haptic feedback
32. Error handling
33. Offline support
34. Push notifications integration
35. Performance optimization

## 10. Flutter Package Requirements

```yaml
dependencies:
  flutter_riverpod: ^2.5.0
  riverpod_annotation: ^2.3.0
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
  riverpod_generator: ^2.3.0
  freezed: ^2.4.0
  json_serializable: ^6.7.0
  riverpod_lint: ^2.3.0
```

## 11. Key Differences (Next.js vs Flutter)

| Feature | Next.js | Flutter |
|---------|---------|---------|
| State Management | React hooks | Riverpod |
| Routing | next/navigation | GoRouter |
| HTTP | fetch API | Dio |
| WebSocket | native WebSocket | web_socket_channel |
| Image Cache | next/image | cached_network_image |
| Animations | Framer Motion | Flutter Animate |
| Voice Recording | MediaRecorder | flutter_sound/record |
| Camera | getUserMedia | camera plugin |
| Local Storage | localStorage | Hive/SharedPreferences |
| Styling | Tailwind CSS | Material 3 ThemeData |

## 12. Success Criteria

The Flutter implementation should:
- ✅ Preserve ALL business logic from Next.js
- ✅ Maintain feature parity (100% coverage)
- ✅ Provide superior native Android UX
- ✅ Run at 60 FPS consistently
- ✅ Support offline-first architecture
- ✅ Handle real-time updates seamlessly
- ✅ Pass code review for Google Play Store
- ✅ Follow Material 3 design guidelines
- ✅ Implement proper error handling
- ✅ Include comprehensive logging
- ✅ Support dark/light themes
- ✅ Be production-ready

---

**Document Version**: 1.0  
**Last Updated**: July 12, 2026  
**Author**: Senior Flutter Engineer  
**Status**: Ready for Implementation
