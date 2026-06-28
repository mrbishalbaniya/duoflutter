import { useRouter } from "expo-router";
import { Ionicons } from "@expo/vector-icons";
import { LinearGradient } from "expo-linear-gradient";
import { Pressable, StyleSheet, Text, View } from "react-native";
import { useAuth } from "@/contexts/AuthContext";
import { useTheme } from "@/contexts/ThemeContext";
import { ProfileAvatar } from "@/components/ui/ProfileAvatar";
import { DuoButton } from "@/components/ui/DuoButton";
import { Screen } from "@/components/ui/Screen";
import { fonts, radius, spacing } from "@/constants/theme";

export default function ProfileScreen() {
  const { user, logout } = useAuth();
  const { colors } = useTheme();
  const router = useRouter();
  const profile = user?.profile;

  if (!profile) return null;

  return (
    <Screen scroll contentStyle={styles.wrap}>
      <LinearGradient
        colors={["#e84a7a44", "#17181a88", colors.background]}
        style={styles.banner}
      />

      <View style={styles.hero}>
        <ProfileAvatar profile={profile} size={100} />
        <Text style={[styles.name, { color: colors.onSurface }]}>
          {profile.full_name || user?.username}
          {profile.age ? `, ${profile.age}` : ""}
        </Text>
        {profile.location ? (
          <View style={styles.loc}>
            <Ionicons name="location" size={14} color={colors.primary} />
            <Text style={{ color: colors.onSurfaceVariant, fontFamily: fonts.body }}>
              {profile.location}
            </Text>
          </View>
        ) : null}
      </View>

      <View style={[styles.card, { backgroundColor: colors.surface, borderColor: colors.border }]}>
        <View style={styles.rowBetween}>
          <Text style={[styles.cardTitle, { color: colors.onSurface }]}>Profile completeness</Text>
          <Text style={{ color: colors.primary, fontFamily: fonts.headlineMedium }}>
            {profile.profile_completeness ?? 0}%
          </Text>
        </View>
        <View style={[styles.bar, { backgroundColor: colors.surfaceContainerHigh }]}>
          <LinearGradient
            colors={["#e84a7a", "#d4a574"]}
            start={{ x: 0, y: 0 }}
            end={{ x: 1, y: 0 }}
            style={[styles.fill, { width: `${profile.profile_completeness ?? 0}%` as `${number}%` }]}
          />
        </View>
      </View>

      {!profile.is_verified ? (
        <Pressable
          onPress={() => router.push("/verify")}
          style={[styles.verifyCta, { borderColor: colors.primary + "44", backgroundColor: colors.primary + "11" }]}
        >
          <Ionicons name="camera" size={24} color={colors.primary} />
          <View style={{ flex: 1 }}>
            <Text style={[styles.cardTitle, { color: colors.onSurface }]}>Verify your profile</Text>
            <Text style={{ color: colors.onSurfaceVariant, fontFamily: fonts.body, fontSize: 13 }}>
              Take a selfie to earn a verified badge
            </Text>
          </View>
          <Ionicons name="chevron-forward" size={20} color={colors.onSurfaceVariant} />
        </Pressable>
      ) : (
        <View style={[styles.card, { backgroundColor: colors.surface, borderColor: colors.border }]}>
          <Ionicons name="shield-checkmark" size={22} color={colors.accent} />
          <Text style={[styles.cardTitle, { color: colors.onSurface, marginTop: spacing.sm }]}>
            Verified profile
          </Text>
        </View>
      )}

      {profile.bio ? (
        <View style={[styles.card, { backgroundColor: colors.surface, borderColor: colors.border }]}>
          <Text style={[styles.sectionLabel, { color: colors.onSurfaceVariant }]}>About</Text>
          <Text style={{ color: colors.onSurface, fontFamily: fonts.body, lineHeight: 22 }}>{profile.bio}</Text>
        </View>
      ) : null}

      <DuoButton label="Settings" variant="outline" onPress={() => router.push("/settings")} />
      <DuoButton label="Log out" variant="ghost" onPress={() => void logout()} style={{ marginTop: spacing.sm }} />
    </Screen>
  );
}

const styles = StyleSheet.create({
  wrap: { paddingBottom: 120 },
  banner: { height: 120, marginHorizontal: -spacing.lg, marginTop: -spacing.lg },
  hero: { alignItems: "center", marginTop: -50, marginBottom: spacing.lg, gap: spacing.sm },
  name: { fontFamily: fonts.headline, fontSize: 26, textAlign: "center" },
  loc: { flexDirection: "row", alignItems: "center", gap: 4 },
  card: {
    marginHorizontal: spacing.lg,
    marginBottom: spacing.md,
    padding: spacing.lg,
    borderRadius: radius.lg,
    borderWidth: 1,
  },
  rowBetween: { flexDirection: "row", justifyContent: "space-between", alignItems: "center" },
  cardTitle: { fontFamily: fonts.headlineMedium, fontSize: 16 },
  bar: { height: 8, borderRadius: 4, marginTop: spacing.md, overflow: "hidden" },
  fill: { height: "100%", borderRadius: 4 },
  verifyCta: {
    flexDirection: "row",
    alignItems: "center",
    gap: spacing.md,
    marginHorizontal: spacing.lg,
    marginBottom: spacing.md,
    padding: spacing.lg,
    borderRadius: radius.lg,
    borderWidth: 1,
  },
  sectionLabel: {
    fontFamily: fonts.headlineMedium,
    fontSize: 12,
    textTransform: "uppercase",
    letterSpacing: 1,
    marginBottom: spacing.sm,
  },
});
