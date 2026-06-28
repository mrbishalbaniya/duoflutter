import { useState } from "react";
import { KeyboardAvoidingView, Platform, Pressable, StyleSheet, Text, TextInput, View } from "react-native";
import { Link, useRouter } from "expo-router";
import { useAuth } from "@/contexts/AuthContext";
import { useTheme } from "@/contexts/ThemeContext";
import { DuoButton } from "@/components/ui/DuoButton";
import { Screen } from "@/components/ui/Screen";
import { fonts, radius, spacing } from "@/constants/theme";

export default function RegisterScreen() {
  const { register } = useAuth();
  const { colors } = useTheme();
  const router = useRouter();
  const [fullName, setFullName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const onSubmit = async () => {
    setError(null);
    setLoading(true);
    try {
      await register(email.trim(), password, fullName.trim());
      router.replace("/(tabs)/match");
    } catch (e) {
      setError(e instanceof Error ? e.message : "Registration failed");
    } finally {
      setLoading(false);
    }
  };

  return (
    <Screen scroll>
      <KeyboardAvoidingView behavior={Platform.OS === "ios" ? "padding" : undefined} style={styles.wrap}>
        <Text style={[styles.logo, { color: colors.primary }]}>Join Duo</Text>
        <Text style={[styles.sub, { color: colors.onSurfaceVariant }]}>
          Start your journey toward a meaningful connection
        </Text>

        <View style={[styles.card, { backgroundColor: colors.surface, borderColor: colors.border }]}>
          {[
            { value: fullName, set: setFullName, placeholder: "Full name" },
            { value: email, set: setEmail, placeholder: "Email", keyboard: "email-address" as const },
            { value: password, set: setPassword, placeholder: "Password", secure: true },
          ].map((field) => (
            <TextInput
              key={field.placeholder}
              value={field.value}
              onChangeText={field.set}
              placeholder={field.placeholder}
              placeholderTextColor={colors.onSurfaceVariant}
              secureTextEntry={field.secure}
              keyboardType={field.keyboard}
              autoCapitalize="none"
              style={[styles.input, { color: colors.onSurface, backgroundColor: colors.surfaceContainerHigh, borderColor: colors.border }]}
            />
          ))}

          {error ? <Text style={styles.error}>{error}</Text> : null}
          <DuoButton label="Create account" onPress={() => void onSubmit()} loading={loading} />
        </View>

        <View style={styles.footer}>
          <Text style={{ color: colors.onSurfaceVariant, fontFamily: fonts.body }}>Already have an account? </Text>
          <Link href="/login" asChild>
            <Pressable>
              <Text style={{ color: colors.primary, fontFamily: fonts.headlineMedium }}>Sign in</Text>
            </Pressable>
          </Link>
        </View>
      </KeyboardAvoidingView>
    </Screen>
  );
}

const styles = StyleSheet.create({
  wrap: { padding: spacing.lg, paddingTop: spacing.xxl },
  logo: { fontFamily: fonts.headline, fontSize: 32, textAlign: "center" },
  sub: { fontFamily: fonts.body, textAlign: "center", marginTop: spacing.sm, marginBottom: spacing.lg },
  card: { borderRadius: radius.xl, borderWidth: 1, padding: spacing.lg, gap: spacing.md },
  input: {
    borderWidth: 1,
    borderRadius: radius.md,
    paddingHorizontal: spacing.md,
    paddingVertical: 14,
    fontFamily: fonts.body,
    fontSize: 16,
  },
  error: { color: "#ef4444", fontFamily: fonts.body },
  footer: { flexDirection: "row", justifyContent: "center", marginTop: spacing.lg },
});
