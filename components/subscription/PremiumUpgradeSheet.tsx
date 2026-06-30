import {
  Modal,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { PremiumPricing } from "@/components/subscription/PremiumPricing";
import { useTheme } from "@/contexts/ThemeContext";
import type { SubscriptionPlan } from "@/types";
import { spacing } from "@/constants/theme";

type Props = {
  open: boolean;
  onClose: () => void;
  plans: SubscriptionPlan[];
  count: number;
  paying: boolean;
  onSubscribe: (planId: string) => void;
};

export function PremiumUpgradeSheet({
  open,
  onClose,
  plans,
  count,
  paying,
  onSubscribe,
}: Props) {
  const { colors } = useTheme();
  const insets = useSafeAreaInsets();

  return (
    <Modal visible={open} transparent animationType="slide" onRequestClose={onClose}>
      <View style={styles.overlay}>
        <Pressable style={styles.backdrop} onPress={onClose} accessibilityLabel="Close premium offer" />
        <View
          style={[
            styles.sheet,
            {
              backgroundColor: colors.background,
              borderColor: colors.border,
              paddingBottom: Math.max(insets.bottom, spacing.lg),
            },
          ]}
        >
          <Pressable onPress={onClose} style={styles.handleHit} accessibilityLabel="Close premium offer">
            <View style={[styles.handle, { backgroundColor: colors.onSurfaceVariant + "44" }]} />
          </Pressable>

          <ScrollView
            contentContainerStyle={styles.content}
            showsVerticalScrollIndicator={false}
            keyboardShouldPersistTaps="handled"
          >
            <PremiumPricing
              plans={plans}
              likesCount={count}
              paying={paying}
              onSubscribe={onSubscribe}
            />
          </ScrollView>
        </View>
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  overlay: { flex: 1, justifyContent: "flex-end" },
  backdrop: {
    ...StyleSheet.absoluteFill,
    backgroundColor: "rgba(0,0,0,0.5)",
  },
  sheet: {
    maxHeight: "92%",
    borderTopLeftRadius: 28,
    borderTopRightRadius: 28,
    borderTopWidth: StyleSheet.hairlineWidth,
    overflow: "hidden",
  },
  handleHit: { alignItems: "center", paddingTop: 10, paddingBottom: 6 },
  handle: { width: 48, height: 5, borderRadius: 999 },
  content: { paddingHorizontal: 20, paddingTop: 8, paddingBottom: 8 },
});
