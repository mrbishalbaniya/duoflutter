import { Ionicons } from "@expo/vector-icons";
import { StyleSheet, Text, View, type ViewStyle } from "react-native";
import { useTheme } from "@/contexts/ThemeContext";
import { fonts, radius, spacing } from "@/constants/theme";

type Props = {
  icon: keyof typeof Ionicons.glyphMap;
  title: string;
  description?: string;
  style?: ViewStyle;
};

export function EmptyState({ icon, title, description, style }: Props) {
  const { colors } = useTheme();
  return (
    <View style={[styles.wrap, style]}>
      <Ionicons name={icon} size={56} color={colors.primary + "55"} />
      <Text style={[styles.title, { color: colors.onSurface }]}>{title}</Text>
      {description ? (
        <Text style={[styles.body, { color: colors.onSurfaceVariant }]}>{description}</Text>
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    flex: 1,
    alignItems: "center",
    justifyContent: "center",
    paddingHorizontal: spacing.lg,
    paddingVertical: spacing.xxl,
    gap: spacing.md,
  },
  title: {
    fontFamily: fonts.headline,
    fontSize: 22,
    textAlign: "center",
  },
  body: {
    fontFamily: fonts.body,
    fontSize: 15,
    lineHeight: 22,
    textAlign: "center",
    maxWidth: 320,
  },
});
