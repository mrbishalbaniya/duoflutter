import { Pressable, StyleSheet, Text, View } from "react-native";
import { useTheme } from "@/contexts/ThemeContext";
import { fonts, radius, spacing } from "@/constants/theme";

type Props<T extends string> = {
  options: { value: T; label: string }[];
  value: T;
  onChange: (value: T) => void;
};

export function SegmentedControl<T extends string>({ options, value, onChange }: Props<T>) {
  const { colors } = useTheme();
  return (
    <View style={[styles.wrap, { backgroundColor: colors.surfaceContainerHigh + "99" }]}>
      {options.map((opt) => {
        const active = opt.value === value;
        return (
          <Pressable
            key={opt.value}
            onPress={() => onChange(opt.value)}
            style={[
              styles.item,
              active && { backgroundColor: colors.surfaceContainerHighest },
            ]}
          >
            <Text
              style={[
                styles.label,
                { color: active ? colors.onSurface : colors.onSurfaceVariant },
              ]}
            >
              {opt.label}
            </Text>
          </Pressable>
        );
      })}
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    flexDirection: "row",
    borderRadius: radius.md,
    padding: 3,
    gap: 2,
  },
  item: {
    flex: 1,
    paddingVertical: spacing.sm,
    paddingHorizontal: spacing.sm,
    borderRadius: radius.md - 4,
    alignItems: "center",
  },
  label: {
    fontFamily: fonts.headlineMedium,
    fontSize: 12,
  },
});
