import { useCallback, useEffect, useState } from "react";
import {
  ActivityIndicator,
  Dimensions,
  Image,
  Pressable,
  StyleSheet,
  Text,
  View,
} from "react-native";
import { useRouter } from "expo-router";
import { Ionicons } from "@expo/vector-icons";
import { LinearGradient } from "expo-linear-gradient";
import api from "@/lib/api";
import { resolveProfilePhotoUrl } from "@/lib/mediaUrl";
import { useTheme } from "@/contexts/ThemeContext";
import { DuoButton } from "@/components/ui/DuoButton";
import { EmptyState } from "@/components/ui/EmptyState";
import { Screen } from "@/components/ui/Screen";
import type { Profile } from "@/types";
import { fonts, radius, spacing } from "@/constants/theme";

const CARD_WIDTH = Dimensions.get("window").width - 48;

export default function MatchScreen() {
  const { colors } = useTheme();
  const router = useRouter();
  const [profiles, setProfiles] = useState<Profile[]>([]);
  const [loading, setLoading] = useState(true);
  const [swiping, setSwiping] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      setProfiles(await api.discoverProfiles());
    } catch {
      setProfiles([]);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  const current = profiles[0];

  const handleSwipe = async (action: "LIKE" | "SKIP") => {
    if (!current || swiping) return;
    const userId = current.user_id ?? current.id;
    if (!userId) return;

    setSwiping(true);
    setProfiles((prev) => prev.slice(1));
    try {
      const res = await api.swipe(userId, action);
      if (res.is_match && res.match) {
        router.push({
          pathname: "/celebration",
          params: {
            name: res.match.other_user_profile.full_name,
            score: String(res.match.compatibility_score),
            photo: resolveProfilePhotoUrl(res.match.other_user_profile),
          },
        });
      }
    } catch {
      void load();
    } finally {
      setSwiping(false);
      if (profiles.length <= 1) void load();
    }
  };

  if (loading) {
    return (
      <Screen style={styles.centered}>
        <ActivityIndicator size="large" color={colors.primary} />
      </Screen>
    );
  }

  if (!current) {
    return (
      <Screen style={styles.centered}>
        <EmptyState
          icon="search"
          title="No profiles to discover"
          description="No one matches your current filters, or you have swiped through everyone nearby."
        />
        <View style={styles.emptyActions}>
          <DuoButton label="Refresh" onPress={() => void load()} variant="primary" />
        </View>
      </Screen>
    );
  }

  return (
    <Screen style={{ backgroundColor: colors.background }}>
      <View style={styles.deck}>
        <View style={[styles.card, { backgroundColor: colors.surface }]}>
          <Image source={{ uri: resolveProfilePhotoUrl(current) }} style={styles.photo} />
          <LinearGradient colors={["transparent", "rgba(0,0,0,0.85)"]} style={styles.overlay}>
            <Text style={styles.name}>
              {current.full_name}
              {current.age ? `, ${current.age}` : ""}
            </Text>
            {current.location ? (
              <View style={styles.locRow}>
                <Ionicons name="location" size={14} color="#fff" />
                <Text style={styles.loc}>{current.location}</Text>
              </View>
            ) : null}
            {current.bio ? <Text style={styles.bio} numberOfLines={2}>{current.bio}</Text> : null}
          </LinearGradient>
        </View>
      </View>

      <View style={styles.actions}>
        <Pressable
          onPress={() => void handleSwipe("SKIP")}
          disabled={swiping}
          style={[styles.actionBtn, { borderColor: colors.error + "55", backgroundColor: colors.surface }]}
        >
          <Ionicons name="close" size={32} color={colors.error} />
        </Pressable>
        <Pressable
          onPress={() => void handleSwipe("LIKE")}
          disabled={swiping}
          style={styles.likeWrap}
        >
          <LinearGradient colors={["#e84a7a", "#d4a574"]} style={styles.likeBtn}>
            <Ionicons name="heart" size={32} color="#fff" />
          </LinearGradient>
        </Pressable>
      </View>
    </Screen>
  );
}

const styles = StyleSheet.create({
  centered: { justifyContent: "center" },
  deck: { flex: 1, alignItems: "center", justifyContent: "center", padding: spacing.lg, paddingBottom: 100 },
  card: {
    width: CARD_WIDTH,
    height: CARD_WIDTH * 1.25,
    borderRadius: radius.lg,
    overflow: "hidden",
  },
  photo: { width: "100%", height: "100%" },
  overlay: { position: "absolute", left: 0, right: 0, bottom: 0, padding: spacing.lg },
  name: { color: "#fff", fontFamily: fonts.headline, fontSize: 24 },
  locRow: { flexDirection: "row", alignItems: "center", gap: 4, marginTop: 4 },
  loc: { color: "#ffffffcc", fontFamily: fonts.body, fontSize: 14 },
  bio: { color: "#ffffffaa", fontFamily: fonts.body, fontSize: 13, marginTop: 8 },
  actions: {
    position: "absolute",
    bottom: 100,
    left: 0,
    right: 0,
    flexDirection: "row",
    justifyContent: "center",
    gap: spacing.xl,
  },
  actionBtn: {
    width: 64,
    height: 64,
    borderRadius: 32,
    borderWidth: 2,
    alignItems: "center",
    justifyContent: "center",
  },
  likeWrap: { borderRadius: 36, overflow: "hidden" },
  likeBtn: { width: 72, height: 72, alignItems: "center", justifyContent: "center" },
  emptyActions: { paddingHorizontal: spacing.xl, width: "100%", marginTop: spacing.md },
});
