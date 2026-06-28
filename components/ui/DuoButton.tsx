import { LinearGradient } from "expo-linear-gradient";
import {
  ActivityIndicator,
  Pressable,
  StyleSheet,
  Text,
  type PressableProps,
  type TextStyle,
  type ViewStyle,
} from "react-native";
import { useTheme } from "@/contexts/ThemeContext";
import { fonts, radius } from "@/constants/theme";

type Props = PressableProps & {
  label: string;
  variant?: "primary" | "outline" | "ghost";
  loading?: boolean;
  style?: ViewStyle;
  textStyle?: TextStyle;
};

export function DuoButton({
  label,
  variant = "primary",
  loading,
  disabled,
  style,
  textStyle,
  ...rest
}: Props) {
  const { colors } = useTheme();
  const isDisabled = disabled || loading;

  if (variant === "primary") {
    return (
      <Pressable disabled={isDisabled} style={[styles.base, style]} {...rest}>
        <LinearGradient
          colors={["#e84a7a", "#ff4d6d", "#d4a574"]}
          start={{ x: 0, y: 0 }}
          end={{ x: 1, y: 1 }}
          style={[styles.gradient, isDisabled && styles.disabled]}
        >
          {loading ? (
            <ActivityIndicator color="#fff" />
          ) : (
            <Text style={[styles.primaryText, textStyle]}>{label}</Text>
          )}
        </LinearGradient>
      </Pressable>
    );
  }

  if (variant === "outline") {
    return (
      <Pressable
        disabled={isDisabled}
        style={[
          styles.base,
          styles.outline,
          { borderColor: colors.primary + "44", backgroundColor: colors.surface },
          isDisabled && styles.disabled,
          style,
        ]}
        {...rest}
      >
        {loading ? (
          <ActivityIndicator color={colors.primary} />
        ) : (
          <Text style={[styles.outlineText, { color: colors.primary }, textStyle]}>{label}</Text>
        )}
      </Pressable>
    );
  }

  return (
    <Pressable
      disabled={isDisabled}
      style={[isDisabled && styles.disabled, style]}
      {...rest}
    >
      <Text style={[styles.ghostText, { color: colors.onSurfaceVariant }, textStyle]}>{label}</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  base: { borderRadius: radius.full, overflow: "hidden" },
  gradient: {
    paddingVertical: 16,
    paddingHorizontal: 28,
    alignItems: "center",
    justifyContent: "center",
  },
  primaryText: {
    color: "#fff",
    fontFamily: fonts.headline,
    fontSize: 16,
  },
  outline: {
    paddingVertical: 14,
    paddingHorizontal: 24,
    borderWidth: 1,
    alignItems: "center",
  },
  outlineText: {
    fontFamily: fonts.headlineMedium,
    fontSize: 15,
  },
  disabled: { opacity: 0.5 },
  ghostText: {
    fontFamily: fonts.bodyMedium,
    fontSize: 15,
    textAlign: "center",
    paddingVertical: 12,
  },
});
