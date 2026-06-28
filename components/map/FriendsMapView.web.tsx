import { StyleSheet, View } from "react-native";
import { useTheme } from "@/contexts/ThemeContext";
import type { MapProfile } from "@/components/map/types";

type Props = {
  profiles: MapProfile[];
  userCoordinates: [number, number] | null;
  focusProfileId?: string | null;
  onProfileFocus?: (profileId: string) => void;
};

export function FriendsMapView(_props: Props) {
  const { resolved } = useTheme();
  const isDark = resolved === "dark";

  return (
    <View style={[styles.webFallback, { backgroundColor: isDark ? "#1d1d1f" : "#e8eaed" }]} />
  );
}

const styles = StyleSheet.create({
  webFallback: { flex: 1 },
});
