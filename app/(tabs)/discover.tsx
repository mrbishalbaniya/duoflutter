import { useCallback, useEffect, useMemo, useState } from "react";
import {
  ActivityIndicator,
  FlatList,
  Pressable,
  StyleSheet,
  Text,
  View,
  useWindowDimensions,
} from "react-native";
import { Ionicons } from "@expo/vector-icons";
import { useLocalSearchParams, useRouter } from "expo-router";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { DiscoverActionButton } from "@/components/discover/DiscoverActionButton";
import { DiscoverProfileCard } from "@/components/discover/DiscoverProfileCard";
import { PremiumUpgradeSheet } from "@/components/subscription/PremiumUpgradeSheet";
import { DuoButton } from "@/components/ui/DuoButton";
import { SegmentedControl } from "@/components/ui/SegmentedControl";
import api from "@/lib/api";
import { chatPath } from "@/lib/chatNavigation";
import {
  DISCOVER_TABS,
  interactionTimeLabel,
  likedProfileKey,
  type DiscoverTab,
} from "@/lib/discoverUtils";
import { submitEsewaPayment } from "@/lib/esewa";
import { resolveProfilePhotoUrl } from "@/lib/mediaUrl";
import { useTheme } from "@/contexts/ThemeContext";
import type { LikedProfile, Match, SubscriptionPlan } from "@/types";
import { fonts, spacing } from "@/constants/theme";

type GridItem =
  | { kind: "match"; data: Match }
  | { kind: "liked"; data: LikedProfile }
  | { kind: "likes-you"; data: LikedProfile };

export default function DiscoverScreen() {
  const { colors } = useTheme();
  const router = useRouter();
  const params = useLocalSearchParams<{ subscription?: string; tab?: string }>();
  const insets = useSafeAreaInsets();
  const { width } = useWindowDimensions();
  const numColumns = width >= 900 ? 3 : 2;

  const [tab, setTab] = useState<DiscoverTab>("matches");
  const [matches, setMatches] = useState<Match[]>([]);
  const [likedByYou, setLikedByYou] = useState<LikedProfile[]>([]);
  const [likesYou, setLikesYou] = useState<LikedProfile[]>([]);
  const [likesYouPremium, setLikesYouPremium] = useState(false);
  const [lockedCount, setLockedCount] = useState(0);
  const [subscriptionPlans, setSubscriptionPlans] = useState<SubscriptionPlan[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);
  const [likingBackId, setLikingBackId] = useState<string | null>(null);
  const [premiumSheetOpen, setPremiumSheetOpen] = useState(false);
  const [paying, setPaying] = useState(false);

  const load = useCallback(async (isRefresh = false) => {
    if (isRefresh) setRefreshing(true);
    else setError(null);
    try {
      const [m, l, y, plans] = await Promise.all([
        api.getMatches(),
        api.getLikedByYou(),
        api.getLikesYou(),
        api.getSubscriptionPlans().catch(() => []),
      ]);
      setMatches(m);
      setLikedByYou(l);
      setLikesYou(y.results);
      setLikesYouPremium(Boolean(y.is_premium));
      setLockedCount(
        y.is_premium ? 0 : (y.count ?? y.results.length)
      );
      setSubscriptionPlans(plans);
      setError(null);
    } catch {
      setError("Could not load your discover lists.");
      setMatches([]);
      setLikedByYou([]);
      setLikesYou([]);
      setLikesYouPremium(false);
      setLockedCount(0);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  useEffect(() => {
    if (params.tab === "likes-you") {
      setTab("likes-you");
    }
    if (params.subscription === "success") {
      setNotice("Payment successful. Duo Premium is now active.");
      setTab("likes-you");
      void load(true);
      router.replace("/(tabs)/discover");
    } else if (params.subscription === "failed") {
      setNotice("Payment was not completed. You can try again with eSewa.");
      setTab("likes-you");
      router.replace("/(tabs)/discover");
    }
  }, [params.subscription, params.tab, load, router]);

  const premiumLikesCount = lockedCount > 0 ? lockedCount : likesYou.length;

  const openPremiumSheet = () => setPremiumSheetOpen(true);

  const handleSubscribe = useCallback(async (planId: string) => {
    setPaying(true);
    setNotice(null);
    try {
      const payment = await api.initiateSubscription(planId);
      submitEsewaPayment(payment.payment_url, payment.form);
    } catch (e) {
      setNotice(
        e instanceof Error ? e.message : "Could not start eSewa payment. Please try again."
      );
      setPaying(false);
    }
  }, []);

  const tabCounts = useMemo(
    () => ({
      matches: matches.length,
      "liked-by-you": likedByYou.length,
      "likes-you": likesYou.length,
    }),
    [matches.length, likedByYou.length, likesYou.length]
  );

  const gridData = useMemo((): GridItem[] => {
    if (tab === "matches") return matches.map((data) => ({ kind: "match" as const, data }));
    if (tab === "liked-by-you") return likedByYou.map((data) => ({ kind: "liked" as const, data }));
    return likesYou.map((data) => ({ kind: "likes-you" as const, data }));
  }, [tab, matches, likedByYou, likesYou]);

  const openMatchChat = async (matchId: number) => {
    const convs = await api.getConversations();
    const conv = convs.find((c) => c.match_id === matchId);
    router.push(conv ? chatPath(conv.id) : chatPath());
  };

  const handleLikeBack = async (item: LikedProfile) => {
    const toUserId = item.profile.user_id ?? item.profile.id;
    if (!toUserId) {
      setNotice("Could not like back — profile is missing a user id.");
      return;
    }

    const key = likedProfileKey(item);
    setLikingBackId(key);
    setNotice(null);

    try {
      const res = await api.swipe(toUserId, "LIKE");
      setLikesYou((prev) => prev.filter((entry) => likedProfileKey(entry) !== key));

      if (res.is_match && res.match) {
        const profile = res.match.other_user_profile;
        router.push({
          pathname: "/celebration",
          params: {
            name: profile.full_name,
            score: String(Math.round(res.match.compatibility_score ?? 0)),
            photo: resolveProfilePhotoUrl(profile),
          },
        });
        return;
      }

      setNotice("You liked them back!");
      void load(true);
    } catch (e) {
      setNotice(e instanceof Error ? e.message : "Like back failed. Please try again.");
    } finally {
      setLikingBackId(null);
    }
  };

  const segmentOptions = DISCOVER_TABS.map((t) => ({
    value: t.id,
    label: tabCounts[t.id] > 0 ? `${t.label} ${tabCounts[t.id]}` : t.label,
  }));

  const renderCard = ({ item }: { item: GridItem }) => {
    if (item.kind === "match") {
      const match = item.data;
      const profile = match.other_user_profile;
      return (
        <DiscoverProfileCard
          profile={profile}
          timeLabel={interactionTimeLabel(undefined, "matched", match.matched_at)}
          style={styles.cardCell}
          actions={
            <>
              <DiscoverActionButton
                icon="chatbubble"
                label="Message"
                primary
                onPress={() => void openMatchChat(match.id)}
              />
              <DiscoverActionButton
                icon="analytics-outline"
                label="Insights"
                onPress={() => router.push("/(tabs)/match")}
              />
            </>
          }
        />
      );
    }

    if (item.kind === "liked") {
      const liked = item.data;
      return (
        <DiscoverProfileCard
          profile={liked.profile}
          timeLabel={interactionTimeLabel(liked.action, "sent", liked.liked_at)}
          style={styles.cardCell}
          actions={
            <DiscoverActionButton
              icon="heart-outline"
              label="Keep swiping"
              full
              onPress={() => router.push("/(tabs)/match")}
            />
          }
        />
      );
    }

    const entry = item.data;
    const locked = !likesYouPremium && (entry.locked ?? true);
    const key = likedProfileKey(entry);

    return (
      <DiscoverProfileCard
        profile={entry.profile}
        locked={locked}
        onLockedPress={locked ? openPremiumSheet : undefined}
        timeLabel={interactionTimeLabel(entry.action, "received", entry.liked_at)}
        style={styles.cardCell}
        actions={
          locked ? undefined : (
            <DiscoverActionButton
              icon="heart"
              label={likingBackId === key ? "Liking…" : "Like back"}
              primary
              full
              loading={likingBackId === key}
              disabled={likingBackId === key}
              onPress={() => void handleLikeBack(entry)}
            />
          )
        }
      />
    );
  };

  const emptyContent = () => {
    if (error) {
      return (
        <View style={styles.empty}>
          <Ionicons name="cloud-offline-outline" size={48} color={colors.primary + "66"} />
          <Text style={[styles.emptyTitle, { color: colors.onSurface }]}>Unable to Load</Text>
          <Text style={[styles.emptyBody, { color: colors.onSurfaceVariant }]}>{error}</Text>
          <DuoButton label="Try Again" onPress={() => void load(true)} style={{ marginTop: spacing.md }} />
        </View>
      );
    }

    const copy = {
      matches: {
        icon: "heart-dislike-outline" as const,
        title: "No Matches",
        description: "When you and someone both like each other, they'll show up here.",
        cta: "Start Swiping",
      },
      "liked-by-you": {
        icon: "thumbs-up-outline" as const,
        title: "No Likes Yet",
        description: "Profiles you like will appear here until they like you back.",
        cta: "Discover Profiles",
      },
      "likes-you": {
        icon: "heart-outline" as const,
        title: "No Likes Yet",
        description: "When someone likes you, they'll appear here so you can match back.",
        cta: "Update Profile",
      },
    }[tab];

    return (
      <View style={styles.empty}>
        <Ionicons name={copy.icon} size={48} color={colors.primary + "66"} />
        <Text style={[styles.emptyTitle, { color: colors.onSurface }]}>{copy.title}</Text>
        <Text style={[styles.emptyBody, { color: colors.onSurfaceVariant }]}>{copy.description}</Text>
        <DuoButton
          label={copy.cta}
          variant="outline"
          onPress={() =>
            router.push(tab === "likes-you" ? "/(tabs)/profile" : "/(tabs)/match")
          }
          style={{ marginTop: spacing.md }}
        />
      </View>
    );
  };

  return (
    <View style={[styles.root, { backgroundColor: colors.background, paddingTop: insets.top }]}>
      <View style={styles.header}>
        <View style={styles.titleRow}>
          <Text style={[styles.title, { color: colors.onSurface }]}>Discover</Text>
          <Pressable onPress={() => void load(true)} hitSlop={8} disabled={refreshing}>
            <Ionicons
              name="refresh"
              size={22}
              color={colors.onSurfaceVariant}
              style={refreshing ? styles.spinning : undefined}
            />
          </Pressable>
        </View>
        <SegmentedControl value={tab} onChange={setTab} options={segmentOptions} />
      </View>

      {notice ? (
        <View style={[styles.notice, { backgroundColor: colors.surfaceContainerHigh, borderColor: colors.border }]}>
          <Text style={[styles.noticeText, { color: colors.onSurface }]}>{notice}</Text>
        </View>
      ) : null}

      {loading ? (
        <ActivityIndicator color={colors.primary} style={{ marginTop: 48 }} />
      ) : gridData.length === 0 ? (
        emptyContent()
      ) : (
        <FlatList
          data={gridData}
          key={numColumns}
          numColumns={numColumns}
          keyExtractor={(item) =>
            item.kind === "match"
              ? `m-${item.data.id}`
              : likedProfileKey(item.data)
          }
          renderItem={renderCard}
          contentContainerStyle={[styles.grid, { paddingBottom: 120 + insets.bottom }]}
          columnWrapperStyle={numColumns > 1 ? styles.row : undefined}
          showsVerticalScrollIndicator={false}
        />
      )}

      <PremiumUpgradeSheet
        open={premiumSheetOpen}
        onClose={() => setPremiumSheetOpen(false)}
        plans={subscriptionPlans}
        count={premiumLikesCount}
        paying={paying}
        onSubscribe={(planId) => void handleSubscribe(planId)}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1 },
  header: { paddingHorizontal: spacing.lg, paddingBottom: spacing.sm, gap: spacing.md },
  titleRow: { flexDirection: "row", alignItems: "center", justifyContent: "space-between" },
  title: { fontFamily: fonts.headline, fontSize: 34, letterSpacing: -0.5 },
  spinning: { opacity: 0.5 },
  notice: {
    marginHorizontal: spacing.lg,
    marginBottom: spacing.sm,
    padding: spacing.md,
    borderRadius: 12,
    borderWidth: StyleSheet.hairlineWidth,
  },
  noticeText: { fontFamily: fonts.body, fontSize: 14 },
  grid: { paddingHorizontal: spacing.md, gap: spacing.md },
  row: { gap: spacing.md },
  cardCell: { flex: 1, maxWidth: "100%" },
  empty: {
    flex: 1,
    alignItems: "center",
    justifyContent: "center",
    paddingHorizontal: spacing.xl,
    paddingBottom: 120,
    gap: spacing.sm,
  },
  emptyTitle: { fontFamily: fonts.headline, fontSize: 22, textAlign: "center" },
  emptyBody: { fontFamily: fonts.body, fontSize: 15, textAlign: "center", lineHeight: 22, maxWidth: 300 },
});
