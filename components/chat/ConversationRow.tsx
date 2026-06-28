import { Pressable, StyleSheet, Text, View } from "react-native";
import { ProfileAvatar } from "@/components/ui/ProfileAvatar";
import {
  formatMessageTime,
  getConversationLastActivity,
  lastMessagePreview,
  displayName,
} from "@/lib/chatUtils";
import { useTheme } from "@/contexts/ThemeContext";
import type { Conversation } from "@/types";
import { fonts } from "@/constants/theme";

type Props = {
  conversation: Conversation;
  selected?: boolean;
  onPress: () => void;
};

export function ConversationRow({ conversation, selected, onPress }: Props) {
  const { colors } = useTheme();
  const time = formatMessageTime(getConversationLastActivity(conversation));
  const unread = conversation.unread_count ?? 0;

  return (
    <Pressable
      onPress={onPress}
      style={[
        styles.row,
        {
          backgroundColor: selected ? colors.surfaceContainerHigh : "transparent",
          borderLeftColor: selected ? colors.primary : "transparent",
        },
      ]}
    >
      <ProfileAvatar profile={conversation.other_user_profile} size={48} />
      <View style={styles.body}>
        <Text style={[styles.name, { color: colors.onSurface }]} numberOfLines={1}>
          {displayName(conversation)}
        </Text>
        <Text style={[styles.preview, { color: colors.onSurfaceVariant }]} numberOfLines={1}>
          {lastMessagePreview(conversation)}
        </Text>
      </View>
      <View style={styles.meta}>
        {time ? (
          <Text style={[styles.time, { color: colors.onSurfaceVariant }]}>{time}</Text>
        ) : null}
        {unread > 0 ? (
          <View style={[styles.badge, { backgroundColor: colors.primary }]}>
            <Text style={styles.badgeText}>{unread > 99 ? "99+" : unread}</Text>
          </View>
        ) : null}
      </View>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  row: {
    flexDirection: "row",
    alignItems: "center",
    gap: 12,
    paddingHorizontal: 16,
    paddingVertical: 14,
    borderLeftWidth: 4,
  },
  body: { flex: 1, minWidth: 0, gap: 2 },
  name: { fontFamily: fonts.headlineMedium, fontSize: 15 },
  preview: { fontFamily: fonts.body, fontSize: 13 },
  meta: { alignItems: "flex-end", justifyContent: "space-between", minHeight: 40, gap: 6 },
  time: { fontFamily: fonts.body, fontSize: 11 },
  badge: {
    minWidth: 18,
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 999,
    alignItems: "center",
  },
  badgeText: { color: "#fff", fontFamily: fonts.headlineMedium, fontSize: 10 },
});
