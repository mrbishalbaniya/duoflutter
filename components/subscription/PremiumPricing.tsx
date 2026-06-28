import { useEffect, useMemo, useState } from "react";
import { ActivityIndicator, Pressable, StyleSheet, Text, View } from "react-native";
import { Ionicons } from "@expo/vector-icons";
import { EsewaMark } from "@/components/payment/EsewaMark";
import { formatNpr } from "@/lib/esewa";
import { useTheme } from "@/contexts/ThemeContext";
import type { SubscriptionPlan } from "@/types";
import { fonts, radius } from "@/constants/theme";

type Props = {
  plans: SubscriptionPlan[];
  likesCount?: number;
  paying?: boolean;
  onSubscribe: (planId: string) => void;
};

export function PremiumPricing({ plans, likesCount = 0, paying, onSubscribe }: Props) {
  const { colors } = useTheme();
  const popularIndex = plans.findIndex((plan) => plan.badge === "Popular");
  const defaultIndex = popularIndex >= 0 ? popularIndex : 0;
  const [active, setActive] = useState(defaultIndex);

  useEffect(() => {
    setActive(defaultIndex);
  }, [defaultIndex, plans.length]);

  const selected = plans[active] ?? plans[0];

  const subtitle = useMemo(() => {
    if (likesCount > 0) {
      return `${likesCount} ${likesCount === 1 ? "person has" : "people have"} liked you. Unlock blurred profiles and match instantly.`;
    }
    return "Upgrade to unlock blurred profiles when someone likes you.";
  }, [likesCount]);

  if (!selected) {
    return (
      <View style={styles.loading}>
        <ActivityIndicator color={colors.primary} />
        <Text style={[styles.loadingText, { color: colors.onSurfaceVariant }]}>
          Loading plans…
        </Text>
      </View>
    );
  }

  return (
    <View style={styles.wrap}>
      <View style={styles.copy}>
        <View style={[styles.badge, { backgroundColor: colors.primary + "1A", borderColor: colors.primary + "40" }]}>
          <Ionicons name="ribbon" size={14} color={colors.primary} />
          <Text style={[styles.badgeText, { color: colors.primary }]}>DUO PREMIUM</Text>
        </View>
        <Text style={[styles.title, { color: colors.onSurface }]}>See who liked you</Text>
        <Text style={[styles.body, { color: colors.onSurfaceVariant }]}>{subtitle}</Text>
        <View style={styles.features}>
          <FeatureRow colors={colors} text="Reveal names and photos on Liked you" />
          <FeatureRow
            colors={colors}
            text={`${selected.duration_days}-day access · ${formatNpr(selected.amount)}`}
          />
        </View>
      </View>

      <View style={[styles.plansCard, { backgroundColor: colors.surfaceContainer, borderColor: colors.border }]}>
        {plans.map((plan, index) => {
          const isActive = active === index;
          return (
            <Pressable
              key={plan.plan_id}
              onPress={() => setActive(index)}
              style={[
                styles.planRow,
                {
                  borderColor: isActive ? colors.primary : colors.border,
                  backgroundColor: isActive ? colors.primary + "14" : colors.background,
                },
              ]}
            >
              <View style={styles.planBody}>
                <View style={styles.planTitleRow}>
                  <Text style={[styles.planName, { color: colors.onSurface }]}>{plan.name}</Text>
                  {plan.badge ? (
                    <View style={[styles.planBadge, { backgroundColor: colors.primary + "26" }]}>
                      <Text style={[styles.planBadgeText, { color: colors.primary }]}>{plan.badge}</Text>
                    </View>
                  ) : null}
                </View>
                <Text style={[styles.planPrice, { color: colors.onSurfaceVariant }]}>
                  <Text style={{ color: colors.onSurface, fontFamily: fonts.headlineMedium }}>
                    NPR {plan.amount.toLocaleString("en-NP")}
                  </Text>
                  {` / ${plan.duration_days} days`}
                </Text>
              </View>
              <View
                style={[
                  styles.radio,
                  { borderColor: isActive ? colors.primary : colors.onSurfaceVariant + "55" },
                ]}
              >
                {isActive ? <View style={[styles.radioDot, { backgroundColor: colors.primary }]} /> : null}
              </View>
            </Pressable>
          );
        })}

        <Pressable
          onPress={() => onSubscribe(selected.plan_id)}
          disabled={paying}
          style={[styles.payBtn, paying && styles.payDisabled]}
        >
          <EsewaMark size={22} />
          <Text style={styles.payText}>{paying ? "Redirecting…" : "Pay with eSewa"}</Text>
        </Pressable>
        <Text style={[styles.payHint, { color: colors.onSurfaceVariant }]}>
          Secure payment in NPR via eSewa ePay
        </Text>
      </View>
    </View>
  );
}

function FeatureRow({
  text,
  colors,
}: {
  text: string;
  colors: { primary: string; onSurfaceVariant: string };
}) {
  return (
    <View style={styles.featureRow}>
      <Ionicons name="checkmark-circle" size={18} color={colors.primary} />
      <Text style={[styles.featureText, { color: colors.onSurfaceVariant }]}>{text}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: { gap: 16 },
  copy: { gap: 8 },
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
  features: { gap: 8, marginTop: 4 },
  featureRow: { flexDirection: "row", alignItems: "center", gap: 8 },
  featureText: { fontFamily: fonts.body, fontSize: 14, flex: 1 },
  plansCard: {
    borderWidth: StyleSheet.hairlineWidth,
    borderRadius: 28,
    padding: 12,
    gap: 10,
  },
  planRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 12,
    borderWidth: 2,
    borderRadius: 16,
    padding: 14,
    minHeight: 88,
  },
  planBody: { flex: 1, minWidth: 0 },
  planTitleRow: { flexDirection: "row", flexWrap: "wrap", alignItems: "center", gap: 8 },
  planName: { fontFamily: fonts.headlineMedium, fontSize: 17 },
  planBadge: { borderRadius: 8, paddingHorizontal: 8, paddingVertical: 2 },
  planBadgeText: { fontFamily: fonts.headlineMedium, fontSize: 10, textTransform: "uppercase" },
  planPrice: { fontFamily: fonts.body, fontSize: 14, marginTop: 4 },
  radio: {
    width: 24,
    height: 24,
    borderRadius: 12,
    borderWidth: 2,
    alignItems: "center",
    justifyContent: "center",
  },
  radioDot: { width: 12, height: 12, borderRadius: 6 },
  payBtn: {
    marginTop: 4,
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
    gap: 8,
    backgroundColor: "#60bb46",
    borderRadius: radius.full,
    paddingVertical: 14,
  },
  payDisabled: { opacity: 0.6 },
  payText: { color: "#fff", fontFamily: fonts.headlineMedium, fontSize: 16 },
  payHint: { textAlign: "center", fontFamily: fonts.body, fontSize: 11 },
  loading: { alignItems: "center", gap: 12, paddingVertical: 32 },
  loadingText: { fontFamily: fonts.body, fontSize: 14 },
});
