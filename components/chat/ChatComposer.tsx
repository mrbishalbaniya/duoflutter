import { LinearGradient } from "expo-linear-gradient";
import {
  ActivityIndicator,
  Pressable,
  StyleSheet,
  Text,
  TextInput,
  View,
} from "react-native";
import { Ionicons } from "@expo/vector-icons";
import { useTheme } from "@/contexts/ThemeContext";
import { fonts, radius } from "@/constants/theme";

type Props = {
  value: string;
  onChangeText: (text: string) => void;
  onSend: () => void;
  sending?: boolean;
  placeholder?: string;
};

export function ChatComposer({
  value,
  onChangeText,
  onSend,
  sending,
  placeholder = "Aa",
}: Props) {
  const { colors } = useTheme();
  const canSend = value.trim().length > 0 && !sending;

  return (
    <View style={[styles.wrap, { backgroundColor: colors.background, borderTopColor: colors.border }]}>
      <View style={[styles.field, { backgroundColor: colors.surfaceContainerHigh, borderColor: colors.border }]}>
        <TextInput
          value={value}
          onChangeText={onChangeText}
          placeholder={placeholder}
          placeholderTextColor={colors.onSurfaceVariant}
          style={[styles.input, { color: colors.onSurface }]}
          multiline
          maxLength={2000}
        />
        <Pressable hitSlop={8}>
          <Ionicons name="happy-outline" size={22} color={colors.primary} />
        </Pressable>
      </View>
      <Pressable
        onPress={onSend}
        disabled={!canSend}
        style={[styles.sendBtn, !canSend && styles.sendDisabled]}
      >
        <LinearGradient
          colors={canSend ? ["#e84a7a", "#ff4d6d", "#d4a574"] : ["#555", "#555"]}
          style={styles.sendGradient}
        >
          {sending ? (
            <ActivityIndicator color="#fff" size="small" />
          ) : (
            <Ionicons name="send" size={18} color="#fff" />
          )}
        </LinearGradient>
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    flexDirection: "row",
    alignItems: "flex-end",
    gap: 10,
    paddingHorizontal: 12,
    paddingVertical: 12,
    borderTopWidth: StyleSheet.hairlineWidth,
  },
  field: {
    flex: 1,
    flexDirection: "row",
    alignItems: "flex-end",
    gap: 8,
    borderWidth: StyleSheet.hairlineWidth,
    borderRadius: radius.full,
    paddingHorizontal: 14,
    paddingVertical: 8,
    minHeight: 44,
    maxHeight: 120,
  },
  input: {
    flex: 1,
    fontFamily: fonts.body,
    fontSize: 15,
    maxHeight: 96,
    paddingVertical: 4,
  },
  sendBtn: { marginBottom: 2 },
  sendDisabled: { opacity: 0.45 },
  sendGradient: {
    width: 40,
    height: 40,
    borderRadius: 20,
    alignItems: "center",
    justifyContent: "center",
  },
});
