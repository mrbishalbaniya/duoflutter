import { Pressable, StyleSheet, Text, View } from "react-native";
import { LinearGradient } from "expo-linear-gradient";
import { Ionicons } from "@expo/vector-icons";
import { EsewaMark } from "@/components/payment/EsewaMark";
import { formatNpr } from "@/lib/esewa";
import { useTheme } from "@/contexts/ThemeContext";
import type { SubscriptionPlan } from "@/types";
import { fonts, radius, spacing } from "@/constants/theme";

type Props = {
  plan: SubscriptionPlan | null;
  count: number;
  paying: boolean;
  onPress: () => void;
};

export function PremiumUpgradeBanner({ plan, count, paying, onPress }: Props) {
  const { colors } = useTheme();
  const priceLabel = plan ? formatNpr(plan.amount) : "Rs. 499";

  return (
    <LinearGradient
      colors={[colors.surfaceContainerHigh, colors.background]}
      style={[styles.banner, { borderColor: colors.border }]}
    >
      <View style={[styles.badge, { backgroundColor: colors.primary + "1A", borderColor: colors.primary + "40" }]}>
        <Ionicons name="ribbon" size={14} color={colors.primary} />
        <Text style={[styles.badgeText, { color: colors.primary }]}>DUO PREMIUM</Text>
      </View>
      <Text style={[styles.title, { color: colors.onSurface }]}>See who liked you</Text>
      <Text style={[styles.body, { color: colors.onSurfaceVariant }]}>
        {count > 0
          ? `${count} ${count === 1 ? "person has" : "people have"} liked you. Unlock blurred profiles and match instantly.`
          : "Upgrade to unlock blurred profiles when someone likes you."}
      </Text>
      <Text style={[styles.price, { color: colors.onSurface }]}>
        {priceLabel}
        <Text style={[styles.priceSub, { color: colors.onSurfaceVariant }]}> / plan</Text>
      </Text>
      <Pressable
        onPress={onPress}
        disabled={paying}
        style={[styles.payBtn, paying && styles.payDisabled]}
      >
        <EsewaMark size={20} />
        <Text style={styles.payText}>{paying ? "Redirecting…" : "Pay with eSewa"}</Text>
      </Pressable>
    </LinearGradient>
  );
}

const styles = StyleSheet.create({
  banner: {
    borderWidth: StyleSheet.hairlineWidth,
    borderRadius: radius.lg,
    padding: 20,
    marginBottom: spacing.md,
    gap: 8,
  },
  badge: {
    alignSelf: "flex-start",
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
    borderWidth: 1,
    borderRadius: radius.full,
    paddingHorizontal: 10,
    paddingVertical: 4,
  },
  badgeText: { fontFamily: fonts.headlineMedium, fontSize: 11, letterSpacing: 1 },
  title: { fontFamily: fonts.headline, fontSize: 22 },
  body: { fontFamily: fonts.body, fontSize: 14, lineHeight: 20 },
  price: { fontFamily: fonts.headline, fontSize: 24, marginTop: 4 },
  priceSub: { fontFamily: fonts.body, fontSize: 14 },
  payBtn: {
    marginTop: 8,
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
    gap: 8,
    backgroundColor: "#60bb46",
    borderRadius: radius.full,
    paddingVertical: 14,
  },
  payDisabled: { opacity: 0.6 },
  payText: { color: "#fff", fontFamily: fonts.headlineMedium, fontSize: 15 },
});
