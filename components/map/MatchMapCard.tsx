import { Pressable, StyleSheet, Text, View } from "react-native";
import { Ionicons } from "@expo/vector-icons";
import { ProfileAvatar } from "@/components/ui/ProfileAvatar";
import { formatDistanceAway } from "@/lib/distance";
import { useTheme } from "@/contexts/ThemeContext";
import type { MapProfile } from "@/components/map/types";
import { fonts } from "@/constants/theme";

type Props = {
  profile: MapProfile;
  isActive?: boolean;
  onPress: () => void;
};

export function MatchMapCard({ profile, isActive = false, onPress }: Props) {
  const { colors } = useTheme();

  return (
    <Pressable
      onPress={onPress}
      style={[
        styles.row,
        isActive && { backgroundColor: colors.primary + "26" },
      ]}
    >
      <View style={isActive ? styles.activeRing : undefined}>
        <ProfileAvatar profile={profile} size={44} />
      </View>
      <View style={styles.body}>
        <Text style={[styles.name, { color: colors.onSurface }]} numberOfLines={1}>
          {profile.full_name}
          {profile.age != null ? `, ${profile.age}` : ""}
        </Text>
        <Text style={[styles.distance, { color: colors.primary }]}>
          {formatDistanceAway(profile.distanceMeters)}
        </Text>
        <Text style={[styles.location, { color: colors.onSurfaceVariant }]} numberOfLines={1}>
          {profile.location || "Nepal"}
        </Text>
      </View>
      <Ionicons name="chevron-forward" size={20} color={colors.onSurfaceVariant + "80"} />
    </Pressable>
  );
}

const styles = StyleSheet.create({
  row: {
    flexDirection: "row",
    alignItems: "center",
    gap: 12,
    paddingHorizontal: 16,
    paddingVertical: 12,
  },
  activeRing: {
    borderRadius: 999,
    borderWidth: 2,
    borderColor: "#e84a7a",
    padding: 1,
  },
  body: { flex: 1, minWidth: 0 },
  name: { fontFamily: fonts.headlineMedium, fontSize: 17 },
  distance: { fontFamily: fonts.headlineMedium, fontSize: 13, marginTop: 2 },
  location: { fontFamily: fonts.body, fontSize: 13, marginTop: 2 },
});
