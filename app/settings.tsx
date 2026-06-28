import { useState } from "react";
import { Pressable, StyleSheet, Text, TextInput, View } from "react-native";
import { useRouter } from "expo-router";
import { Ionicons } from "@expo/vector-icons";
import { useAuth } from "@/contexts/AuthContext";
import { useTheme } from "@/contexts/ThemeContext";
import api from "@/lib/api";
import { DuoButton } from "@/components/ui/DuoButton";
import { Screen } from "@/components/ui/Screen";
import type { ThemeMode } from "@/types";
import { fonts, radius, spacing } from "@/constants/theme";

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  const { colors } = useTheme();
  return (
    <View style={styles.section}>
      <Text style={[styles.sectionTitle, { color: colors.onSurfaceVariant }]}>{title}</Text>
      <View style={[styles.sectionBody, { backgroundColor: colors.surface, borderColor: colors.border }]}>
        {children}
      </View>
    </View>
  );
}

function ThemePill({
  mode,
  label,
  icon,
  active,
  onPress,
}: {
  mode: ThemeMode;
  label: string;
  icon: keyof typeof Ionicons.glyphMap;
  active: boolean;
  onPress: (m: ThemeMode) => void;
}) {
  const { colors } = useTheme();
  return (
    <Pressable
      onPress={() => onPress(mode)}
      style={[
        styles.themePill,
        {
          borderColor: active ? colors.primary : colors.outlineVariant,
          backgroundColor: active ? colors.primary + "18" : "transparent",
        },
      ]}
    >
      <Ionicons name={icon} size={22} color={active ? colors.primary : colors.onSurfaceVariant} />
      <Text style={{ color: active ? colors.primary : colors.onSurfaceVariant, fontFamily: fonts.headlineMedium, fontSize: 12 }}>
        {label}
      </Text>
    </Pressable>
  );
}

export default function SettingsScreen() {
  const router = useRouter();
  const { user, logout } = useAuth();
  const { mode, setMode, colors } = useTheme();
  const [current, setCurrent] = useState("");
  const [next, setNext] = useState("");
  const [confirm, setConfirm] = useState("");
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const changePassword = async () => {
    setError(null);
    setMessage(null);
    if (next !== confirm) {
      setError("Passwords do not match");
      return;
    }
    setSaving(true);
    try {
      const res = await api.changePassword(current, next);
      setMessage(res.message);
      setCurrent("");
      setNext("");
      setConfirm("");
    } catch (e) {
      setError(e instanceof Error ? e.message : "Could not update password");
    } finally {
      setSaving(false);
    }
  };

  return (
    <Screen scroll>
      <Pressable onPress={() => router.back()} style={styles.back}>
        <Ionicons name="arrow-back" size={24} color={colors.primary} />
      </Pressable>

      <Section title="Verification">
        {user?.profile?.is_verified ? (
          <View style={styles.row}>
            <Ionicons name="checkmark-circle" size={22} color={colors.accent} />
            <Text style={{ color: colors.onSurface, fontFamily: fonts.headlineMedium }}>Verified profile</Text>
          </View>
        ) : (
          <Pressable onPress={() => router.push("/verify")} style={styles.row}>
            <Ionicons name="camera" size={22} color={colors.primary} />
            <View style={{ flex: 1 }}>
              <Text style={{ color: colors.onSurface, fontFamily: fonts.headlineMedium }}>Verify your profile</Text>
              <Text style={{ color: colors.onSurfaceVariant, fontSize: 13 }}>Take a selfie for a verified badge</Text>
            </View>
            <Ionicons name="chevron-forward" size={18} color={colors.onSurfaceVariant} />
          </Pressable>
        )}
      </Section>

      <Section title="Appearance">
        <View style={styles.themeRow}>
          <ThemePill mode="dark" label="Dark" icon="moon" active={mode === "dark"} onPress={setMode} />
          <ThemePill mode="light" label="Light" icon="sunny" active={mode === "light"} onPress={setMode} />
          <ThemePill mode="system" label="System" icon="phone-portrait-outline" active={mode === "system"} onPress={setMode} />
        </View>
      </Section>

      <Section title="Security">
        <View style={{ padding: spacing.md, gap: spacing.sm }}>
          <TextInput
            secureTextEntry
            placeholder="Current password"
            placeholderTextColor={colors.onSurfaceVariant}
            value={current}
            onChangeText={setCurrent}
            style={[styles.input, { color: colors.onSurface, backgroundColor: colors.surfaceContainerHigh, borderColor: colors.border }]}
          />
          <TextInput
            secureTextEntry
            placeholder="New password"
            placeholderTextColor={colors.onSurfaceVariant}
            value={next}
            onChangeText={setNext}
            style={[styles.input, { color: colors.onSurface, backgroundColor: colors.surfaceContainerHigh, borderColor: colors.border }]}
          />
          <TextInput
            secureTextEntry
            placeholder="Confirm password"
            placeholderTextColor={colors.onSurfaceVariant}
            value={confirm}
            onChangeText={setConfirm}
            style={[styles.input, { color: colors.onSurface, backgroundColor: colors.surfaceContainerHigh, borderColor: colors.border }]}
          />
          {error ? <Text style={styles.error}>{error}</Text> : null}
          {message ? <Text style={{ color: colors.accent }}>{message}</Text> : null}
          <DuoButton label="Update password" onPress={() => void changePassword()} loading={saving} />
        </View>
      </Section>

      <Section title="Account">
        <View style={[styles.row, { borderBottomWidth: StyleSheet.hairlineWidth, borderBottomColor: colors.border }]}>
          <Ionicons name="mail" size={20} color={colors.onSurfaceVariant} />
          <Text style={{ color: colors.onSurfaceVariant, fontFamily: fonts.body }}>{user?.email}</Text>
        </View>
        <Pressable onPress={() => void logout()} style={styles.row}>
          <Ionicons name="log-out" size={20} color="#f87171" />
          <Text style={{ color: "#f87171", fontFamily: fonts.headlineMedium }}>Log out</Text>
        </Pressable>
      </Section>
    </Screen>
  );
}

const styles = StyleSheet.create({
  back: { padding: spacing.lg, paddingBottom: 0 },
  section: { paddingHorizontal: spacing.lg, marginBottom: spacing.lg },
  sectionTitle: {
    fontFamily: fonts.headlineMedium,
    fontSize: 11,
    textTransform: "uppercase",
    letterSpacing: 1.2,
    marginBottom: spacing.sm,
    paddingLeft: 4,
  },
  sectionBody: { borderRadius: radius.lg, borderWidth: 1, overflow: "hidden" },
  row: { flexDirection: "row", alignItems: "center", gap: spacing.md, padding: spacing.md },
  themeRow: { flexDirection: "row", gap: spacing.sm, padding: spacing.md },
  themePill: {
    flex: 1,
    alignItems: "center",
    gap: 6,
    paddingVertical: spacing.md,
    borderRadius: radius.md,
    borderWidth: 1,
  },
  input: {
    borderWidth: 1,
    borderRadius: radius.md,
    paddingHorizontal: spacing.md,
    paddingVertical: 12,
    fontFamily: fonts.body,
  },
  error: { color: "#ef4444", fontFamily: fonts.body },
});
