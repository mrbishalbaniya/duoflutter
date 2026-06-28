import { useCallback, useEffect, useMemo, useState } from "react";
import {
  ActivityIndicator,
  Image,
  Pressable,
  StyleSheet,
  Text,
  View,
} from "react-native";
import { Ionicons } from "@expo/vector-icons";
import { useRouter } from "expo-router";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { FriendsMapView } from "@/components/map/FriendsMapView";
import { MatchBrowseSheet, type MatchBrowseSheetSnap } from "@/components/map/MatchBrowseSheet";
import { MatchMapCard } from "@/components/map/MatchMapCard";
import { profileKey, type MapProfile } from "@/components/map/types";
import { DuoButton } from "@/components/ui/DuoButton";
import { useAuth } from "@/contexts/AuthContext";
import { useTheme } from "@/contexts/ThemeContext";
import api from "@/lib/api";
import { haversineMeters, formatDistanceAway } from "@/lib/distance";
import { resolveProfileCoordinates } from "@/lib/locationCoords";
import { resolveProfilePhotoUrl } from "@/lib/mediaUrl";
import { useUserCoordinates } from "@/lib/useUserCoordinates";
import type { Match } from "@/types";
import { fonts, radius, spacing } from "@/constants/theme";

function matchesToMapProfiles(
  matches: Match[],
  userCoords: [number, number]
): MapProfile[] {
  return matches
    .map((match) => {
      const profile = match.other_user_profile;
      const coordinates = resolveProfileCoordinates(
        profile.location,
        profile.user_id ?? profile.id
      );
      return {
        ...profile,
        matchId: match.id,
        coordinates,
        distanceMeters: haversineMeters(userCoords, coordinates),
      };
    })
    .sort((a, b) => a.distanceMeters - b.distanceMeters)
    .map((profile, index) => ({ ...profile, browseOrder: index }));
}

function FriendsListBody({
  matches,
  loading,
  waitingForLocation,
  error,
  focusProfileId,
  onProfileFocus,
  onRetry,
  onSelect,
}: {
  matches: MapProfile[];
  loading: boolean;
  waitingForLocation: boolean;
  error: string | null;
  focusProfileId: string | null;
  onProfileFocus: (id: string) => void;
  onRetry: () => void;
  onSelect?: () => void;
}) {
  const { colors } = useTheme();
  const router = useRouter();

  if (loading) {
    return (
      <View style={styles.loadingList}>
        <ActivityIndicator color={colors.primary} />
      </View>
    );
  }

  if (waitingForLocation) {
    return (
      <View style={styles.centered}>
        <Text style={[styles.muted, { color: colors.onSurfaceVariant }]}>
          Finding your location…
        </Text>
      </View>
    );
  }

  if (error) {
    return (
      <View style={styles.centered}>
        <Text style={[styles.muted, { color: colors.onSurfaceVariant }]}>{error}</Text>
        <DuoButton label="Try again" onPress={onRetry} style={{ marginTop: spacing.md }} />
      </View>
    );
  }

  if (matches.length > 0) {
    return (
      <View style={styles.listGroup}>
        {matches.map((profile, index) => {
          const key = profileKey(profile);
          return (
            <View key={key}>
              {index > 0 ? (
                <View style={[styles.divider, { backgroundColor: colors.border + "40" }]} />
              ) : null}
              <MatchMapCard
                profile={profile}
                isActive={focusProfileId === key}
                onPress={() => {
                  onProfileFocus(key);
                  onSelect?.();
                }}
              />
            </View>
          );
        })}
      </View>
    );
  }

  return (
    <View style={styles.emptyList}>
      <View style={[styles.emptyIcon, { backgroundColor: colors.surfaceContainerHigh }]}>
        <Ionicons name="people-outline" size={28} color={colors.primary + "80"} />
      </View>
      <Text style={[styles.emptyTitle, { color: colors.onSurface }]}>No friends on the map yet</Text>
      <Text style={[styles.muted, { color: colors.onSurfaceVariant }]}>
        Match with someone to see them here.
      </Text>
      <DuoButton
        label="Go to Discover"
        onPress={() => router.push("/(tabs)/match")}
        style={{ marginTop: spacing.md }}
      />
    </View>
  );
}

export default function MapScreen() {
  const { user } = useAuth();
  const { colors, resolved } = useTheme();
  const isDark = resolved === "dark";
  const router = useRouter();
  const insets = useSafeAreaInsets();
  const [rawMatches, setRawMatches] = useState<Match[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [focusProfileId, setFocusProfileId] = useState<string | null>(null);
  const [sheetSnap, setSheetSnap] = useState<MatchBrowseSheetSnap>("map");

  const userCoords = useUserCoordinates(user?.profile?.location, user?.id);

  const matches = useMemo(() => {
    if (!userCoords) return [];
    return matchesToMapProfiles(rawMatches, userCoords);
  }, [rawMatches, userCoords]);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      setRawMatches(await api.getMatches());
    } catch {
      setError("Could not load your matches.");
      setRawMatches([]);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    if (user) void load();
  }, [user, load]);

  const focusedProfile = useMemo(
    () =>
      focusProfileId
        ? matches.find((p) => profileKey(p) === focusProfileId) ?? null
        : null,
    [matches, focusProfileId]
  );

  const waitingForLocation = !userCoords;
  const glassBg = isDark ? "rgba(27, 29, 32, 0.88)" : "rgba(255, 255, 255, 0.88)";
  const subtitle = loading
    ? "Loading…"
    : waitingForLocation
      ? "Finding your location…"
      : `${matches.length} ${matches.length === 1 ? "match" : "matches"} nearby`;

  const showMap =
    !loading && !waitingForLocation && !error && matches.length > 0;

  return (
    <View style={[styles.root, { backgroundColor: colors.background }]}>
      {showMap ? (
        <FriendsMapView
          profiles={matches}
          userCoordinates={userCoords}
          focusProfileId={focusProfileId}
          onProfileFocus={setFocusProfileId}
        />
      ) : (
        <View style={[styles.placeholder, { backgroundColor: colors.background }]}>
          {loading ? (
            <ActivityIndicator color={colors.primary} size="large" />
          ) : waitingForLocation ? (
            <Text style={[styles.muted, { color: colors.onSurfaceVariant }]}>
              Finding your location…
            </Text>
          ) : error ? (
            <View style={styles.centered}>
              <Text style={[styles.muted, { color: colors.onSurfaceVariant }]}>{error}</Text>
              <DuoButton label="Try again" onPress={() => void load()} style={{ marginTop: spacing.md }} />
            </View>
          ) : (
            <View style={styles.centered}>
              <View style={[styles.emptyIconLg, { backgroundColor: colors.surfaceContainerHigh }]}>
                <Ionicons name="map-outline" size={36} color={colors.primary + "80"} />
              </View>
              <Text style={[styles.muted, { color: colors.onSurfaceVariant, maxWidth: 260, textAlign: "center" }]}>
                Match with someone to see them on the map.
              </Text>
              <DuoButton
                label="Start matching"
                onPress={() => router.push("/(tabs)/match")}
                style={{ marginTop: spacing.lg }}
              />
            </View>
          )}
        </View>
      )}

      <View
        style={[styles.header, { top: insets.top + spacing.sm }]}
        pointerEvents="box-none"
      >
        <View style={[styles.headerGlass, { backgroundColor: glassBg, borderColor: colors.border }]}>
          <View style={[styles.headerIcon, { backgroundColor: colors.primary + "33" }]}>
            <Ionicons name="map" size={20} color={colors.primary} />
          </View>
          <View style={styles.headerText}>
            <Text style={[styles.headerTitle, { color: colors.onSurface }]}>Friends Map</Text>
            <Text style={[styles.headerSub, { color: colors.onSurfaceVariant }]}>{subtitle}</Text>
          </View>
        </View>
      </View>

      {showMap ? (
        <MatchBrowseSheet
          snap={sheetSnap}
          onSnapChange={setSheetSnap}
          matchCount={matches.length}
          hidden={loading && matches.length === 0}
        >
          <FriendsListBody
            matches={matches}
            loading={loading}
            waitingForLocation={waitingForLocation}
            error={error}
            focusProfileId={focusProfileId}
            onProfileFocus={setFocusProfileId}
            onRetry={() => void load()}
            onSelect={() => setSheetSnap("map")}
          />
        </MatchBrowseSheet>
      ) : null}

      {focusedProfile && showMap ? (
        <View
          style={[styles.focusCard, { bottom: 88 + insets.bottom }]}
          pointerEvents="box-none"
        >
          <View style={[styles.focusInner, { backgroundColor: glassBg, borderColor: colors.border }]}>
            <Image
              source={{ uri: resolveProfilePhotoUrl(focusedProfile) }}
              style={styles.focusAvatar}
            />
            <View style={styles.focusBody}>
              <Text style={[styles.focusName, { color: colors.onSurface }]} numberOfLines={1}>
                {focusedProfile.full_name}
                {focusedProfile.age != null ? `, ${focusedProfile.age}` : ""}
              </Text>
              <Text style={[styles.focusDistance, { color: colors.primary }]}>
                {formatDistanceAway(focusedProfile.distanceMeters)}
              </Text>
              <Text style={[styles.focusLocation, { color: colors.onSurfaceVariant }]} numberOfLines={1}>
                {focusedProfile.location || "Nepal"}
              </Text>
            </View>
            <Pressable
              onPress={() => router.push("/(tabs)/chat")}
              style={[styles.chatBtn, { backgroundColor: colors.primary }]}
            >
              <Ionicons name="chatbubble" size={18} color="#fff" />
            </Pressable>
            <Pressable
              onPress={() => setFocusProfileId(null)}
              style={[styles.closeBtn, { backgroundColor: colors.surfaceContainerHigh }]}
            >
              <Ionicons name="close" size={18} color={colors.onSurfaceVariant} />
            </Pressable>
          </View>
        </View>
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1 },
  placeholder: { flex: 1, alignItems: "center", justifyContent: "center", padding: spacing.lg },
  header: {
    position: "absolute",
    left: spacing.md,
    right: spacing.md,
    zIndex: 25,
  },
  headerGlass: {
    flexDirection: "row",
    alignItems: "center",
    gap: spacing.sm,
    paddingHorizontal: spacing.md,
    paddingVertical: 12,
    borderRadius: radius.md,
    borderWidth: StyleSheet.hairlineWidth,
    shadowColor: "#000",
    shadowOpacity: 0.2,
    shadowRadius: 12,
    shadowOffset: { width: 0, height: 4 },
    elevation: 8,
  },
  headerIcon: {
    width: 36,
    height: 36,
    borderRadius: 18,
    alignItems: "center",
    justifyContent: "center",
  },
  headerText: { flex: 1, minWidth: 0 },
  headerTitle: { fontFamily: fonts.headlineMedium, fontSize: 17 },
  headerSub: { fontFamily: fonts.body, fontSize: 13, marginTop: 1 },
  focusCard: {
    position: "absolute",
    left: spacing.md,
    right: spacing.md,
    zIndex: 30,
  },
  focusInner: {
    flexDirection: "row",
    alignItems: "center",
    gap: spacing.sm,
    padding: spacing.sm,
    borderRadius: radius.md,
    borderWidth: StyleSheet.hairlineWidth,
    shadowColor: "#000",
    shadowOpacity: 0.25,
    shadowRadius: 16,
    shadowOffset: { width: 0, height: 6 },
    elevation: 10,
  },
  focusAvatar: {
    width: 48,
    height: 48,
    borderRadius: 24,
    borderWidth: 2,
    borderColor: "rgba(255,255,255,0.25)",
  },
  focusBody: { flex: 1, minWidth: 0 },
  focusName: { fontFamily: fonts.headlineMedium, fontSize: 17 },
  focusDistance: { fontFamily: fonts.headlineMedium, fontSize: 13, marginTop: 2 },
  focusLocation: { fontFamily: fonts.body, fontSize: 13, marginTop: 2 },
  chatBtn: {
    width: 40,
    height: 40,
    borderRadius: 20,
    alignItems: "center",
    justifyContent: "center",
  },
  closeBtn: {
    width: 32,
    height: 32,
    borderRadius: 16,
    alignItems: "center",
    justifyContent: "center",
  },
  loadingList: { paddingVertical: spacing.xl, alignItems: "center" },
  centered: { alignItems: "center", paddingVertical: spacing.xl, paddingHorizontal: spacing.md },
  muted: { fontFamily: fonts.body, fontSize: 15, textAlign: "center" },
  listGroup: { marginHorizontal: spacing.sm },
  divider: { height: StyleSheet.hairlineWidth, marginHorizontal: spacing.md },
  emptyList: { alignItems: "center", paddingVertical: spacing.xl, paddingHorizontal: spacing.md },
  emptyIcon: {
    width: 56,
    height: 56,
    borderRadius: radius.md,
    alignItems: "center",
    justifyContent: "center",
    marginBottom: spacing.sm,
  },
  emptyIconLg: {
    width: 64,
    height: 64,
    borderRadius: radius.md,
    alignItems: "center",
    justifyContent: "center",
    marginBottom: spacing.md,
  },
  emptyTitle: { fontFamily: fonts.headlineMedium, fontSize: 17, marginBottom: spacing.xs },
});
