import { useMemo, useState } from "react";
import {
  ActivityIndicator,
  FlatList,
  Pressable,
  StyleSheet,
  Text,
  TextInput,
  View,
} from "react-native";
import { Ionicons } from "@expo/vector-icons";
import { ConversationRow } from "@/components/chat/ConversationRow";
import { sortConversations } from "@/lib/chatUtils";
import { useTheme } from "@/contexts/ThemeContext";
import type { Conversation } from "@/types";
import { fonts, radius, spacing } from "@/constants/theme";

type Props = {
  conversations: Conversation[];
  loading: boolean;
  selectedId?: number | null;
  onSelect: (conversation: Conversation) => void;
  onRefresh: () => void;
  compact?: boolean;
  borderColor?: string;
};

export function ChatListPanel({
  conversations,
  loading,
  selectedId,
  onSelect,
  onRefresh,
  compact,
  borderColor,
}: Props) {
  const { colors } = useTheme();
  const [search, setSearch] = useState("");

  const filtered = useMemo(() => {
    const sorted = sortConversations(conversations);
    const q = search.trim().toLowerCase();
    if (!q) return sorted;
    return sorted.filter((convo) => {
      const name =
        convo.other_user_nickname?.trim().toLowerCase() ||
        convo.other_user_profile?.full_name?.toLowerCase() ||
        "";
      return name.includes(q);
    });
  }, [conversations, search]);

  const totalUnread = conversations.reduce((sum, c) => sum + (c.unread_count || 0), 0);

  return (
    <View style={[styles.panel, compact && [styles.compact, borderColor ? { borderRightColor: borderColor } : null], { backgroundColor: colors.background }]}>
      <View style={[styles.header, { borderBottomColor: colors.border }]}>
        <View style={styles.titleRow}>
          <Text style={[styles.title, { color: colors.onSurface }]}>Messages</Text>
          {totalUnread > 0 ? (
            <View style={[styles.totalBadge, { backgroundColor: colors.primary }]}>
              <Text style={styles.totalBadgeText}>{totalUnread > 99 ? "99+" : totalUnread}</Text>
            </View>
          ) : null}
          <Pressable onPress={onRefresh} hitSlop={8} style={styles.refresh}>
            <Ionicons name="refresh" size={20} color={colors.onSurfaceVariant} />
          </Pressable>
        </View>
        <View style={[styles.searchWrap, { backgroundColor: colors.surfaceContainerHigh, borderColor: colors.border }]}>
          <Ionicons name="search" size={18} color={colors.onSurfaceVariant} />
          <TextInput
            value={search}
            onChangeText={setSearch}
            placeholder="Search conversations..."
            placeholderTextColor={colors.onSurfaceVariant}
            style={[styles.search, { color: colors.onSurface }]}
          />
        </View>
      </View>

      {loading ? (
        <ActivityIndicator color={colors.primary} style={{ marginTop: 40 }} />
      ) : filtered.length === 0 ? (
        <Text style={[styles.emptySearch, { color: colors.onSurfaceVariant }]}>
          {search.trim() ? "No matches for your search." : "No conversations yet."}
        </Text>
      ) : (
        <FlatList
          data={filtered}
          keyExtractor={(c) => String(c.id)}
          renderItem={({ item }) => (
            <ConversationRow
              conversation={item}
              selected={selectedId === item.id}
              onPress={() => onSelect(item)}
            />
          )}
          contentContainerStyle={{ paddingBottom: compact ? spacing.md : 120 }}
          showsVerticalScrollIndicator={false}
        />
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  panel: { flex: 1 },
  compact: { maxWidth: 400, borderRightWidth: StyleSheet.hairlineWidth },
  header: { paddingHorizontal: spacing.md, paddingTop: spacing.md, paddingBottom: spacing.sm, borderBottomWidth: StyleSheet.hairlineWidth },
  titleRow: { flexDirection: "row", alignItems: "center", gap: 8, marginBottom: spacing.sm },
  title: { fontFamily: fonts.headline, fontSize: 20, flex: 1 },
  totalBadge: { paddingHorizontal: 8, paddingVertical: 2, borderRadius: radius.full },
  totalBadgeText: { color: "#fff", fontFamily: fonts.headlineMedium, fontSize: 11 },
  refresh: { padding: 4 },
  searchWrap: {
    flexDirection: "row",
    alignItems: "center",
    gap: 8,
    borderWidth: StyleSheet.hairlineWidth,
    borderRadius: radius.md,
    paddingHorizontal: 12,
    paddingVertical: 10,
  },
  search: { flex: 1, fontFamily: fonts.body, fontSize: 14, padding: 0 },
  emptySearch: { textAlign: "center", marginTop: 40, fontFamily: fonts.body, fontSize: 14, paddingHorizontal: spacing.lg },
});
