import { Image, StyleSheet, Text, View } from "react-native";
import { useLocalSearchParams, useRouter } from "expo-router";
import { LinearGradient } from "expo-linear-gradient";
import { DuoButton } from "@/components/ui/DuoButton";
import { Screen } from "@/components/ui/Screen";
import { fonts, spacing } from "@/constants/theme";

export default function CelebrationScreen() {
  const router = useRouter();
  const params = useLocalSearchParams<{ name?: string; score?: string; photo?: string }>();

  return (
    <Screen style={styles.wrap}>
      <LinearGradient colors={["#e84a7a33", "#0f0f10"]} style={StyleSheet.absoluteFill} />
      <Text style={styles.heading}>It&apos;s a Match!</Text>
      <Text style={styles.sub}>You and {params.name ?? "someone"} liked each other</Text>

      {params.photo ? (
        <Image source={{ uri: params.photo }} style={styles.photo} />
      ) : null}

      {params.score ? (
        <Text style={styles.score}>{params.score}% compatible</Text>
      ) : null}

      <View style={styles.actions}>
        <DuoButton label="Start chatting" onPress={() => router.replace("/(tabs)/chat")} />
        <DuoButton label="Keep swiping" variant="outline" onPress={() => router.replace("/(tabs)/match")} />
      </View>
    </Screen>
  );
}

const styles = StyleSheet.create({
  wrap: { justifyContent: "center", alignItems: "center", padding: spacing.xl },
  heading: { fontFamily: fonts.headline, fontSize: 34, color: "#fff", marginBottom: spacing.sm },
  sub: { fontFamily: fonts.body, color: "#ffffffaa", marginBottom: spacing.xl, textAlign: "center" },
  photo: { width: 120, height: 120, borderRadius: 60, marginBottom: spacing.md, borderWidth: 3, borderColor: "#e84a7a" },
  score: { fontFamily: fonts.headlineMedium, color: "#d4a574", fontSize: 18, marginBottom: spacing.xl },
  actions: { width: "100%", gap: spacing.md },
});
