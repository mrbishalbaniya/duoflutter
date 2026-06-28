import { LinearGradient } from "expo-linear-gradient";
import { Ionicons } from "@expo/vector-icons";
import { Pressable, StyleSheet, Text, View } from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { useTheme } from "@/contexts/ThemeContext";
import { fonts, radius } from "@/constants/theme";

type TabBarProps = {
  state: { index: number; routes: { key: string; name: string }[] };
  navigation: { navigate: (name: string) => void };
};

const TAB_META: Record<string, { label: string; icon: keyof typeof Ionicons.glyphMap }> = {
  discover: { label: "Discover", icon: "people" },
  chat: { label: "Chat", icon: "chatbubble" },
  match: { label: "Match", icon: "heart" },
  map: { label: "Map", icon: "map" },
  profile: { label: "Profile", icon: "person" },
};

export function DuoTabBar({ state, navigation }: TabBarProps) {
  const insets = useSafeAreaInsets();
  const { colors } = useTheme();

  return (
    <View style={[styles.shell, { paddingBottom: Math.max(insets.bottom, 10) }]}>
      <View style={[styles.bar, { backgroundColor: colors.surface + "ee", borderColor: colors.border }]}>
        {state.routes.map((route, index) => {
          const meta = TAB_META[route.name] ?? { label: route.name, icon: "ellipse" as const };
          const active = state.index === index;
          const isMatch = route.name === "match";

          if (isMatch) {
            return (
              <Pressable key={route.key} onPress={() => navigation.navigate(route.name as never)} style={styles.center}>
                <LinearGradient
                  colors={["#e84a7a", "#d4a574"]}
                  style={[styles.fab, active && styles.fabActive]}
                >
                  <Ionicons name="heart" size={28} color="#fff" />
                </LinearGradient>
              </Pressable>
            );
          }

          const iconName = active ? meta.icon : (`${meta.icon}-outline` as keyof typeof Ionicons.glyphMap);

          return (
            <Pressable
              key={route.key}
              onPress={() => navigation.navigate(route.name)}
              style={styles.tab}
            >
              <Ionicons
                name={iconName}
                size={22}
                color={active ? colors.primary : colors.onSurfaceVariant}
              />
              <Text
                style={[
                  styles.label,
                  { color: active ? colors.primary : colors.onSurfaceVariant },
                ]}
              >
                {meta.label}
              </Text>
              {active ? <View style={[styles.dot, { backgroundColor: colors.primary }]} /> : null}
            </Pressable>
          );
        })}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  shell: {
    position: "absolute",
    left: 0,
    right: 0,
    bottom: 0,
    paddingHorizontal: 12,
    paddingTop: 8,
  },
  bar: {
    flexDirection: "row",
    alignItems: "flex-end",
    borderRadius: radius.full,
    borderWidth: 1,
    paddingHorizontal: 6,
    paddingVertical: 8,
    shadowColor: "#e84a7a",
    shadowOpacity: 0.15,
    shadowRadius: 20,
    elevation: 8,
  },
  tab: {
    flex: 1,
    alignItems: "center",
    gap: 2,
    paddingVertical: 4,
  },
  label: {
    fontFamily: fonts.headlineMedium,
    fontSize: 10,
  },
  dot: {
    width: 4,
    height: 4,
    borderRadius: 2,
    marginTop: 2,
  },
  center: {
    marginTop: -28,
    paddingHorizontal: 4,
  },
  fab: {
    width: 56,
    height: 56,
    borderRadius: 28,
    alignItems: "center",
    justifyContent: "center",
    borderWidth: 2,
    borderColor: "#fff",
  },
  fabActive: {
    transform: [{ scale: 1.04 }],
  },
});
