import { LinearGradient } from "expo-linear-gradient";
import { StyleSheet, Text, View } from "react-native";
import { ProfileAvatar } from "@/components/ui/ProfileAvatar";
import { formatClockTime } from "@/lib/chatUtils";
import { useTheme } from "@/contexts/ThemeContext";
import type { Message, Profile } from "@/types";
import { fonts, radius } from "@/constants/theme";

type Props = {
  message: Message;
  otherProfile?: Profile;
};

export function MessageBubble({ message, otherProfile }: Props) {
  const { colors } = useTheme();
  const time = formatClockTime(message.timestamp ?? message.created_at);

  if (message.is_mine) {
    return (
      <View style={styles.mineWrap}>
        <LinearGradient
          colors={["#e84a7a", "#ff4d6d", "#d4a574"]}
          start={{ x: 0, y: 0 }}
          end={{ x: 1, y: 1 }}
          style={styles.mineBubble}
        >
          <Text style={styles.mineText}>{message.content}</Text>
          <View style={styles.metaRow}>
            <Text style={styles.mineTime}>{time}</Text>
            <Text style={styles.readIcon}>{message.is_read ? "✓✓" : "✓"}</Text>
          </View>
        </LinearGradient>
      </View>
    );
  }

  return (
    <View style={styles.theirsWrap}>
      <ProfileAvatar profile={otherProfile ?? { full_name: message.sender_name }} size={32} />
      <View style={[styles.theirsBubble, { backgroundColor: colors.surfaceContainerHigh, borderColor: colors.border }]}>
        <Text style={[styles.theirsText, { color: colors.onSurface }]}>{message.content}</Text>
        <Text style={[styles.theirsTime, { color: colors.onSurfaceVariant }]}>{time}</Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  mineWrap: { alignSelf: "flex-end", maxWidth: "78%", marginBottom: 10 },
  mineBubble: {
    borderTopLeftRadius: 20,
    borderTopRightRadius: 20,
    borderBottomLeftRadius: 20,
    borderBottomRightRadius: 4,
    paddingHorizontal: 14,
    paddingVertical: 10,
    shadowColor: "#e84a7a",
    shadowOpacity: 0.15,
    shadowRadius: 8,
    shadowOffset: { width: 0, height: 4 },
    elevation: 3,
  },
  mineText: { color: "#fff", fontFamily: fonts.body, fontSize: 15, lineHeight: 21 },
  metaRow: { flexDirection: "row", alignItems: "center", justifyContent: "flex-end", gap: 4, marginTop: 4 },
  mineTime: { color: "rgba(255,255,255,0.7)", fontSize: 10, fontFamily: fonts.body },
  readIcon: { color: "rgba(255,255,255,0.7)", fontSize: 10, fontFamily: fonts.body },
  theirsWrap: {
    flexDirection: "row",
    alignItems: "flex-end",
    gap: 8,
    alignSelf: "flex-start",
    maxWidth: "82%",
    marginBottom: 10,
  },
  theirsBubble: {
    flex: 1,
    borderTopLeftRadius: 20,
    borderTopRightRadius: 20,
    borderBottomRightRadius: 20,
    borderBottomLeftRadius: 4,
    borderWidth: StyleSheet.hairlineWidth,
    paddingHorizontal: 14,
    paddingVertical: 10,
  },
  theirsText: { fontFamily: fonts.body, fontSize: 15, lineHeight: 21 },
  theirsTime: { fontFamily: fonts.body, fontSize: 10, marginTop: 4 },
});
