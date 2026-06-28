import { useRouter } from "expo-router";
import { StyleSheet, Text, View } from "react-native";
import { useAuth } from "@/contexts/AuthContext";
import { useTheme } from "@/contexts/ThemeContext";
import { DuoButton } from "@/components/ui/DuoButton";
import { Screen } from "@/components/ui/Screen";
import { fonts, spacing } from "@/constants/theme";

export default function VerifyScreen() {
  const router = useRouter();
  const { colors } = useTheme();
  const { user } = useAuth();
  const verified = user?.profile?.is_verified;

  return (
    <Screen style={styles.centered}>
      <Text style={[styles.title, { color: colors.onSurface }]}>
        {verified ? "You're verified" : "Profile verification"}
      </Text>
      <Text style={[styles.body, { color: colors.onSurfaceVariant }]}>
        {verified
          ? "Your identity has been verified. This badge builds trust with matches."
          : "Selfie verification with liveness checks will be available here. Wire expo-camera to complete the flow from DuoFrontend's VerificationFlow."}
      </Text>
      <View style={styles.actions}>
        {!verified ? (
          <DuoButton label="Start verification (coming soon)" onPress={() => {}} disabled />
        ) : null}
        <DuoButton label="Back" variant="outline" onPress={() => router.back()} />
      </View>
    </Screen>
  );
}

const styles = StyleSheet.create({
  centered: { justifyContent: "center", padding: spacing.lg },
  title: { fontFamily: fonts.headline, fontSize: 26, textAlign: "center", marginBottom: spacing.md },
  body: { fontFamily: fonts.body, fontSize: 15, lineHeight: 22, textAlign: "center", marginBottom: spacing.xl },
  actions: { gap: spacing.md },
});
