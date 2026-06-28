import { useCallback, useEffect, useRef, useState } from "react";
import {
  ActivityIndicator,
  FlatList,
  KeyboardAvoidingView,
  Platform,
  Pressable,
  StyleSheet,
  Text,
  View,
} from "react-native";
import { Ionicons } from "@expo/vector-icons";
import { useRouter } from "expo-router";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { ChatComposer } from "@/components/chat/ChatComposer";
import { MessageBubble } from "@/components/chat/MessageBubble";
import { ProfileAvatar } from "@/components/ui/ProfileAvatar";
import api from "@/lib/api";
import { closeChatSocket, getChatWebSocketUrl, type ChatWsEvent } from "@/lib/chatWebSocket";
import { displayName, normalizeMessages } from "@/lib/chatUtils";
import { useAuth } from "@/contexts/AuthContext";
import { useTheme } from "@/contexts/ThemeContext";
import type { Conversation, Message } from "@/types";
import { fonts, spacing } from "@/constants/theme";

type Props = {
  conversationId: number;
  conversation?: Conversation | null;
  showBack?: boolean;
  onBack?: () => void;
};

export function ChatThreadPanel({
  conversationId,
  conversation,
  showBack = true,
  onBack,
}: Props) {
  const router = useRouter();
  const insets = useSafeAreaInsets();
  const { colors } = useTheme();
  const { user } = useAuth();
  const listRef = useRef<FlatList<Message>>(null);
  const socketRef = useRef<WebSocket | null>(null);
  const [messages, setMessages] = useState<Message[]>([]);
  const [detail, setDetail] = useState<Conversation | null>(conversation ?? null);
  const [text, setText] = useState("");
  const [loading, setLoading] = useState(true);
  const [sending, setSending] = useState(false);
  const [isOtherUserTyping, setIsOtherUserTyping] = useState(false);

  const load = useCallback(async () => {
    if (!conversationId) return;
    setLoading(true);
    try {
      const [msgs, convs] = await Promise.all([
        api.getMessages(conversationId),
        api.getConversations(),
      ]);
      setMessages(normalizeMessages(msgs));
      setDetail(convs.find((c) => c.id === conversationId) ?? conversation ?? null);
    } catch {
      setMessages([]);
    } finally {
      setLoading(false);
    }
  }, [conversationId, conversation]);

  useEffect(() => {
    void load();
  }, [load]);

  useEffect(() => {
    if (messages.length > 0) {
      requestAnimationFrame(() => listRef.current?.scrollToEnd({ animated: false }));
    }
  }, [messages.length, loading]);

  useEffect(() => {
    if (!conversationId || !user?.id) return;

    let cancelled = false;
    let socket: WebSocket | null = null;

    void (async () => {
      try {
        const ticket = await api.getWsTicket(conversationId);
        if (cancelled) return;

        socket = new WebSocket(getChatWebSocketUrl(conversationId, ticket));
        socketRef.current = socket;

        socket.onmessage = (event) => {
          const data = JSON.parse(String(event.data)) as ChatWsEvent;

          if (data.type === "chat_message") {
            const incoming: Message = {
              id: data.id,
              sender_id: data.sender_id,
              content: data.content,
              image_url: data.image_url ?? "",
              timestamp: data.timestamp,
              sender_name: data.sender_name,
              is_mine: data.sender_id === user.id,
              is_read: false,
            };
            setMessages((prev) => {
              if (prev.some((m) => m.id === incoming.id)) return prev;
              return [...prev, incoming];
            });
            requestAnimationFrame(() => listRef.current?.scrollToEnd({ animated: true }));
          } else if (data.type === "typing_status" && data.user_id !== user.id) {
            setIsOtherUserTyping(Boolean(data.is_typing));
            if (data.is_typing) {
              setTimeout(() => setIsOtherUserTyping(false), 3000);
            }
          } else if (data.type === "message_deleted") {
            if (data.delete_type === "for_everyone") {
              setMessages((prev) =>
                prev.map((m) =>
                  m.id === data.id
                    ? { ...m, content: "This message was deleted", image_url: "" }
                    : m
                )
              );
            } else if (data.user_id === user.id) {
              setMessages((prev) => prev.filter((m) => m.id !== data.id));
            }
          }
        };
      } catch (err) {
        console.warn("WebSocket connection failed:", err);
      }
    })();

    return () => {
      cancelled = true;
      closeChatSocket(socket);
      if (socketRef.current === socket) socketRef.current = null;
    };
  }, [conversationId, user?.id]);

  const send = async () => {
    if (!text.trim() || sending) return;
    const content = text.trim();
    setSending(true);
    try {
      if (socketRef.current?.readyState === WebSocket.OPEN) {
        socketRef.current.send(
          JSON.stringify({ type: "chat_message", content, image_url: "" })
        );
        setText("");
        return;
      }
      const msg = await api.sendMessage(conversationId, content);
      setMessages((prev) => [...prev, msg]);
      setText("");
      requestAnimationFrame(() => listRef.current?.scrollToEnd({ animated: true }));
    } finally {
      setSending(false);
    }
  };

  const profile = detail?.other_user_profile;
  const name = detail ? displayName(detail) : "Chat";
  const typing = isOtherUserTyping || detail?.is_other_user_typing;

  const handleBack = () => {
    if (onBack) onBack();
    else router.back();
  };

  return (
    <KeyboardAvoidingView
      style={[styles.root, { backgroundColor: colors.background }]}
      behavior={Platform.OS === "ios" ? "padding" : undefined}
      keyboardVerticalOffset={Platform.OS === "ios" ? 8 : 0}
    >
      <View style={[styles.header, { borderBottomColor: colors.border, paddingTop: insets.top + 8 }]}>
        {showBack ? (
          <Pressable onPress={handleBack} hitSlop={8} style={styles.backBtn}>
            <Ionicons name="chevron-back" size={28} color={colors.primary} />
          </Pressable>
        ) : null}
        {profile ? <ProfileAvatar profile={profile} size={40} /> : null}
        <View style={styles.headerText}>
          <Text style={[styles.headerName, { color: colors.onSurface }]} numberOfLines={1}>
            {name}
          </Text>
          {typing ? (
            <Text style={[styles.typing, { color: colors.primary }]}>Typing…</Text>
          ) : (
            <Text style={[styles.status, { color: colors.onSurfaceVariant }]}>Active now</Text>
          )}
        </View>
        <Pressable hitSlop={8} style={styles.menuBtn}>
          <Ionicons name="ellipsis-vertical" size={20} color={colors.onSurfaceVariant} />
        </Pressable>
      </View>

      <FlatList
        ref={listRef}
        data={messages}
        keyExtractor={(m) => String(m.id)}
        style={[styles.list, { backgroundColor: colors.surfaceContainer }]}
        contentContainerStyle={styles.listContent}
        renderItem={({ item }) => <MessageBubble message={item} otherProfile={profile} />}
        ListHeaderComponent={
          <View style={styles.startDivider}>
            <View style={[styles.startPill, { backgroundColor: colors.surfaceContainerHigh }]}>
              <Text style={[styles.startText, { color: colors.onSurfaceVariant }]}>
                START OF CONVERSATION
              </Text>
            </View>
          </View>
        }
        ListEmptyComponent={
          loading ? (
            <ActivityIndicator color={colors.primary} style={{ marginTop: 40 }} />
          ) : (
            <Text style={[styles.empty, { color: colors.onSurfaceVariant }]}>
              Say hello to start the conversation.
            </Text>
          )
        }
      />

      <ChatComposer
        value={text}
        onChangeText={setText}
        onSend={() => void send()}
        sending={sending}
      />
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1 },
  header: {
    flexDirection: "row",
    alignItems: "center",
    gap: 10,
    paddingHorizontal: 12,
    paddingBottom: 12,
    borderBottomWidth: StyleSheet.hairlineWidth,
  },
  backBtn: { marginRight: -4 },
  headerText: { flex: 1, minWidth: 0 },
  headerName: { fontFamily: fonts.headlineMedium, fontSize: 17 },
  typing: { fontFamily: fonts.headlineMedium, fontSize: 13, marginTop: 2 },
  status: { fontFamily: fonts.body, fontSize: 13, marginTop: 2 },
  menuBtn: { padding: 4 },
  list: { flex: 1 },
  listContent: { paddingHorizontal: 16, paddingVertical: 16, paddingBottom: 8 },
  startDivider: { alignItems: "center", marginBottom: 16 },
  startPill: { paddingHorizontal: 14, paddingVertical: 6, borderRadius: 999 },
  startText: { fontFamily: fonts.headlineMedium, fontSize: 10, letterSpacing: 1 },
  empty: { textAlign: "center", marginTop: 40, fontFamily: fonts.body, fontSize: 14 },
});
