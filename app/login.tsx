import { useEffect, useState } from "react";
import {
  KeyboardAvoidingView,
  Platform,
  Pressable,
  StyleSheet,
  Text,
  TextInput,
  View,
} from "react-native";
import { Link, useRouter } from "expo-router";
import { GoogleSignInButton } from "@/components/auth/GoogleSignInButton";
import { useAuth } from "@/contexts/AuthContext";
import { useTheme } from "@/contexts/ThemeContext";
import { DuoButton } from "@/components/ui/DuoButton";
import { Screen } from "@/components/ui/Screen";
import { getGoogleSignInHint, useGoogleSignIn } from "@/lib/googleAuth";
import { fonts, radius, spacing } from "@/constants/theme";

export default function LoginScreen() {
  const { login, loginWithGoogle } = useAuth();
  const { colors } = useTheme();
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const { idToken, promptAsync, isReady } = useGoogleSignIn();
  const googleHint = getGoogleSignInHint();

  useEffect(() => {
    if (!idToken) return;
    setLoading(true);
    setError(null);
    void loginWithGoogle(idToken)
      .then((data) => {
        if (!data.user?.profile?.is_onboarded) {
          router.replace("/register");
          return;
        }
        router.replace("/(tabs)/match");
      })
      .catch((e) => {
        setError(e instanceof Error ? e.message : "Google sign-in failed");
      })
      .finally(() => setLoading(false));
  }, [idToken, loginWithGoogle, router]);

  const onSubmit = async () => {
    setError(null);
    setLoading(true);
    try {
      await login(email.trim(), password);
      router.replace("/(tabs)/match");
    } catch (e) {
      setError(e instanceof Error ? e.message : "Login failed");
    } finally {
      setLoading(false);
    }
  };

  const onGooglePress = () => {
    if (!isReady) return;
    void promptAsync();
  };

  return (
    <Screen>
      <KeyboardAvoidingView
        behavior={Platform.OS === "ios" ? "padding" : undefined}
        style={styles.flex}
      >
        <View style={styles.header}>
          <Text style={[styles.logo, { color: colors.primary }]}>Duo</Text>
          <Text style={[styles.sub, { color: colors.onSurfaceVariant }]}>
            Find your life partner, intuitively
          </Text>
        </View>

        <View style={[styles.card, { backgroundColor: colors.surface, borderColor: colors.border }]}>
          <Text style={[styles.title, { color: colors.onSurface }]}>Welcome back</Text>

          <GoogleSignInButton
            onPress={onGooglePress}
            disabled={loading || !isReady}
            hint={googleHint}
          />

          <View style={styles.dividerRow}>
            <View style={[styles.divider, { backgroundColor: colors.border }]} />
            <Text style={[styles.dividerText, { color: colors.onSurfaceVariant }]}>or</Text>
            <View style={[styles.divider, { backgroundColor: colors.border }]} />
          </View>

          <TextInput
            value={email}
            onChangeText={setEmail}
            placeholder="Email"
            placeholderTextColor={colors.onSurfaceVariant}
            autoCapitalize="none"
            keyboardType="email-address"
            style={[styles.input, { color: colors.onSurface, backgroundColor: colors.surfaceContainerHigh, borderColor: colors.border }]}
          />
          <TextInput
            value={password}
            onChangeText={setPassword}
            placeholder="Password"
            placeholderTextColor={colors.onSurfaceVariant}
            secureTextEntry
            style={[styles.input, { color: colors.onSurface, backgroundColor: colors.surfaceContainerHigh, borderColor: colors.border }]}
          />

          {error ? <Text style={styles.error}>{error}</Text> : null}

          <DuoButton label="Sign in" onPress={() => void onSubmit()} loading={loading} style={styles.cta} />
        </View>

        <View style={styles.footer}>
          <Text style={{ color: colors.onSurfaceVariant, fontFamily: fonts.body }}>
            New to Duo?{" "}
          </Text>
          <Link href="/register" asChild>
            <Pressable>
              <Text style={{ color: colors.primary, fontFamily: fonts.headlineMedium }}>Create account</Text>
            </Pressable>
          </Link>
        </View>
      </KeyboardAvoidingView>
    </Screen>
  );
}

const styles = StyleSheet.create({
  flex: { flex: 1, padding: spacing.lg, justifyContent: "center" },
  header: { alignItems: "center", marginBottom: spacing.xl },
  logo: { fontFamily: fonts.headline, fontSize: 42 },
  sub: { fontFamily: fonts.body, marginTop: spacing.sm, textAlign: "center" },
  card: {
    borderRadius: radius.xl,
    borderWidth: 1,
    padding: spacing.lg,
    gap: spacing.md,
  },
  title: { fontFamily: fonts.headline, fontSize: 22, marginBottom: spacing.sm },
  dividerRow: { flexDirection: "row", alignItems: "center", gap: spacing.sm },
  divider: { flex: 1, height: StyleSheet.hairlineWidth },
  dividerText: { fontFamily: fonts.body, fontSize: 13 },
  input: {
    borderWidth: 1,
    borderRadius: radius.md,
    paddingHorizontal: spacing.md,
    paddingVertical: 14,
    fontFamily: fonts.body,
    fontSize: 16,
  },
  error: { color: "#ef4444", fontFamily: fonts.body, fontSize: 14 },
  cta: { marginTop: spacing.sm },
  footer: { flexDirection: "row", justifyContent: "center", marginTop: spacing.lg },
});
