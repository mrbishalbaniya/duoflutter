import { ActivityIndicator, Pressable, StyleSheet, Text, View, type ViewStyle } from "react-native";
import { Ionicons } from "@expo/vector-icons";
import { useTheme } from "@/contexts/ThemeContext";
import { fonts, radius } from "@/constants/theme";

type Props = {
  label: string;
  icon: keyof typeof Ionicons.glyphMap;
  onPress?: () => void;
  primary?: boolean;
  full?: boolean;
  disabled?: boolean;
  loading?: boolean;
  style?: ViewStyle;
};

export function DiscoverActionButton({
  label,
  icon,
  onPress,
  primary,
  full,
  disabled,
  loading,
  style,
}: Props) {
  const { colors } = useTheme();

  return (
    <Pressable
      onPress={onPress}
      disabled={disabled || loading}
      style={[
        styles.btn,
        full && styles.full,
        primary
          ? { backgroundColor: colors.primary }
          : { backgroundColor: colors.surfaceContainerHigh },
        (disabled || loading) && styles.disabled,
        style,
      ]}
    >
      {loading ? (
        <ActivityIndicator color={primary ? "#fff" : colors.primary} size="small" />
      ) : (
        <>
          <Ionicons name={icon} size={14} color={primary ? "#fff" : colors.onSurface} />
          <Text
            style={[
              styles.label,
              { color: primary ? "#fff" : colors.onSurface },
            ]}
          >
            {label}
          </Text>
        </>
      )}
    </Pressable>
  );
}

const styles = StyleSheet.create({
  btn: {
    flex: 1,
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
    gap: 4,
    paddingHorizontal: 10,
    paddingVertical: 10,
    borderRadius: radius.full,
  },
  full: { flex: 1, width: "100%" },
  disabled: { opacity: 0.6 },
  label: { fontFamily: fonts.headlineMedium, fontSize: 11 },
});
