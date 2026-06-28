import { useCallback, useEffect, useMemo, useState } from "react";
import { Platform, StyleSheet, useWindowDimensions, View } from "react-native";
import { useLocalSearchParams, useRouter } from "expo-router";
import { ChatListPanel } from "@/components/chat/ChatListPanel";
import { ChatThreadPanel } from "@/components/chat/ChatThreadPanel";
import { DuoButton } from "@/components/ui/DuoButton";
import { EmptyState } from "@/components/ui/EmptyState";
import api from "@/lib/api";
import { chatPath, parseConversationId } from "@/lib/chatNavigation";
import { useTheme } from "@/contexts/ThemeContext";
import type { Conversation } from "@/types";
import { spacing } from "@/constants/theme";

const SPLIT_MIN_WIDTH = 1024;

export function ChatExperience() {
  const { colors } = useTheme();
  const router = useRouter();
  const params = useLocalSearchParams<{ conversation?: string }>();
  const { width } = useWindowDimensions();

  const split = width >= SPLIT_MIN_WIDTH;
  const conversationId = parseConversationId(params.conversation);
  const inThread = conversationId != null;

  const [conversations, setConversations] = useState<Conversation[]>([]);
  const [loading, setLoading] = useState(true);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      setConversations(await api.getConversations());
    } catch {
      setConversations([]);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  const openConversation = useCallback(
    (id: number) => {
      router.replace(chatPath(id));
    },
    [router]
  );

  const closeConversation = useCallback(() => {
    router.replace(chatPath());
  }, [router]);

  useEffect(() => {
    if (loading || !split || inThread || conversations.length === 0) return;
    openConversation(conversations[0].id);
  }, [loading, split, inThread, conversations, openConversation]);

  useEffect(() => {
    if (loading || !inThread || conversationId == null) return;
    if (!conversations.some((c) => c.id === conversationId)) {
      closeConversation();
    }
  }, [loading, inThread, conversationId, conversations, closeConversation]);

  const selected = useMemo(
    () => conversations.find((c) => c.id === conversationId) ?? null,
    [conversations, conversationId]
  );

  if (!loading && conversations.length === 0) {
    return (
      <View style={[styles.emptyWrap, { backgroundColor: colors.background }]}>
        <EmptyState
          icon="chatbubbles-outline"
          title="No conversations yet"
          description="Start swiping to find matches and begin chatting!"
        />
        <DuoButton
          label="Find Matches"
          onPress={() => router.push("/(tabs)/match")}
          style={{ marginTop: spacing.lg }}
        />
      </View>
    );
  }

  if (split) {
    return (
      <View style={[styles.split, { backgroundColor: colors.background }]}>
        <ChatListPanel
          conversations={conversations}
          loading={loading}
          selectedId={conversationId}
          onSelect={(c) => openConversation(c.id)}
          onRefresh={() => void load()}
          compact
          borderColor={colors.border}
        />
        {inThread && conversationId ? (
          <ChatThreadPanel
            conversationId={conversationId}
            conversation={selected}
            showBack={false}
          />
        ) : (
          <View style={[styles.placeholder, { backgroundColor: colors.surfaceContainer }]}>
            <EmptyState
              icon="chatbubble-outline"
              title="Select a conversation"
              description="Choose a match to start messaging."
              style={{ paddingVertical: spacing.xl }}
            />
          </View>
        )}
      </View>
    );
  }

  return (
    <View style={[styles.mobileRoot, { backgroundColor: colors.background }]}>
      <View
        style={[styles.listPane, inThread && styles.listPaneHidden]}
        pointerEvents={inThread ? "none" : "auto"}
      >
        <ChatListPanel
          conversations={conversations}
          loading={loading}
          selectedId={conversationId}
          onSelect={(c) => openConversation(c.id)}
          onRefresh={() => void load()}
        />
      </View>

      {inThread && conversationId ? (
        <View style={[styles.threadOverlay, { backgroundColor: colors.background }]}>
          <ChatThreadPanel
            conversationId={conversationId}
            conversation={selected}
            showBack
            onBack={closeConversation}
          />
        </View>
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  split: { flex: 1, flexDirection: "row" },
  placeholder: { flex: 1, alignItems: "center", justifyContent: "center" },
  emptyWrap: { flex: 1, justifyContent: "center" },
  mobileRoot: { flex: 1, overflow: "hidden" },
  listPane: { flex: 1 },
  listPaneHidden: {
    ...Platform.select({
      web: { display: "none" as const },
      default: { opacity: 0 },
    }),
  },
  threadOverlay: {
    ...StyleSheet.absoluteFillObject,
    zIndex: 20,
  },
});
