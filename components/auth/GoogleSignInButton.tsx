import { Pressable, StyleSheet, Text, View } from "react-native";
import { Ionicons } from "@expo/vector-icons";
import { useTheme } from "@/contexts/ThemeContext";
import { fonts, radius, spacing } from "@/constants/theme";

type Props = {
  onPress: () => void;
  disabled?: boolean;
  hint?: string | null;
};

export function GoogleSignInButton({ onPress, disabled = false, hint }: Props) {
  const { colors } = useTheme();

  if (hint) {
    return (
      <Text style={[styles.hint, { color: colors.onSurfaceVariant }]}>{hint}</Text>
    );
  }

  return (
    <Pressable
      onPress={onPress}
      disabled={disabled}
      style={({ pressed }) => [
        styles.button,
        { borderColor: colors.border, opacity: disabled ? 0.5 : pressed ? 0.85 : 1 },
      ]}
    >
      <Ionicons name="logo-google" size={20} color={colors.onSurface} />
      <Text style={[styles.label, { color: colors.onSurface }]}>Continue with Google</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  button: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
    gap: spacing.sm,
    borderWidth: 1,
    borderRadius: radius.full,
    paddingVertical: 14,
    paddingHorizontal: spacing.lg,
  },
  label: { fontFamily: fonts.headlineMedium, fontSize: 15 },
  hint: { fontFamily: fonts.body, fontSize: 13, textAlign: "center" },
});
