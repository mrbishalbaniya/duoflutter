import { useEffect, useMemo, useRef } from "react";
import { Image, Platform, StyleSheet, Text, View } from "react-native";
import MapView, { Marker, type Region } from "react-native-maps";
import { formatDistanceCompact } from "@/lib/distance";
import { NEPAL_MAP_DEFAULT_CENTER } from "@/lib/locationCoords";
import { resolveProfilePhotoUrl } from "@/lib/mediaUrl";
import { mapDarkStyle } from "@/components/map/mapDarkStyle";
import { profileKey, type MapProfile } from "@/components/map/types";
import { useTheme } from "@/contexts/ThemeContext";
import { fonts } from "@/constants/theme";

const MARKER_FOCUS_DELTA = 0.04;
const FIT_PADDING = 50;

function isValidCoord(c: unknown): c is [number, number] {
  return (
    Array.isArray(c) &&
    c.length === 2 &&
    Number.isFinite(c[0]) &&
    Number.isFinite(c[1]) &&
    !(c[0] === 0 && c[1] === 0)
  );
}

type Props = {
  profiles: MapProfile[];
  userCoordinates: [number, number] | null;
  focusProfileId?: string | null;
  onProfileFocus?: (profileId: string) => void;
};

function PinMarker({
  profile,
  onPress,
}: {
  profile: MapProfile;
  onPress: () => void;
}) {
  const { colors } = useTheme();

  return (
    <Marker
      coordinate={{ latitude: profile.coordinates[0], longitude: profile.coordinates[1] }}
      onPress={(e) => {
        e.stopPropagation();
        onPress();
      }}
      anchor={{ x: 0.5, y: 1 }}
    >
      <View style={styles.markerColumn} collapsable={false}>
        <View style={styles.avatarRing}>
          <Image
            source={{ uri: resolveProfilePhotoUrl(profile) }}
            style={styles.avatar}
          />
        </View>
        <View style={[styles.distancePill, { backgroundColor: colors.surfaceContainerHighest + "F2" }]}>
          <Text style={[styles.distanceText, { color: colors.onSurface }]}>
            {formatDistanceCompact(profile.distanceMeters)}
          </Text>
        </View>
        <View style={[styles.dot, { backgroundColor: colors.primary, borderColor: "#fff" }]} />
      </View>
    </Marker>
  );
}

function UserPin({ coordinates }: { coordinates: [number, number] }) {
  return (
    <Marker
      coordinate={{ latitude: coordinates[0], longitude: coordinates[1] }}
      anchor={{ x: 0.5, y: 0.5 }}
    >
      <View style={styles.userPin} collapsable={false}>
        <View style={styles.userPulseOuter} />
        <View style={styles.userPulseInner} />
        <View style={styles.userDot} />
      </View>
    </Marker>
  );
}

export function FriendsMapView({
  profiles,
  userCoordinates,
  focusProfileId,
  onProfileFocus,
}: Props) {
  const { resolved } = useTheme();
  const isDark = resolved === "dark";
  const mapRef = useRef<MapView>(null);

  const mappableProfiles = useMemo(
    () => profiles.filter((p) => isValidCoord(p.coordinates)),
    [profiles]
  );

  const initialRegion: Region = useMemo(() => {
    const [lat, lng] = userCoordinates ?? NEPAL_MAP_DEFAULT_CENTER;
    return {
      latitude: lat,
      longitude: lng,
      latitudeDelta: 0.12,
      longitudeDelta: 0.12,
    };
  }, [userCoordinates]);

  const fitKey = useMemo(
    () =>
      [
        userCoordinates?.join(","),
        ...mappableProfiles.map(
          (p) => `${profileKey(p)}:${p.coordinates[0]},${p.coordinates[1]}`
        ),
      ].join("|"),
    [mappableProfiles, userCoordinates]
  );

  useEffect(() => {
    if (!mapRef.current) return;

    const coords = mappableProfiles.map((p) => ({
      latitude: p.coordinates[0],
      longitude: p.coordinates[1],
    }));

    if (userCoordinates && isValidCoord(userCoordinates)) {
      coords.push({ latitude: userCoordinates[0], longitude: userCoordinates[1] });
    }

    if (coords.length === 0) return;

    if (coords.length === 1) {
      mapRef.current.animateToRegion(
        { ...coords[0], latitudeDelta: 0.08, longitudeDelta: 0.08 },
        400
      );
      return;
    }

    mapRef.current.fitToCoordinates(coords, {
      edgePadding: { top: FIT_PADDING + 80, right: FIT_PADDING, bottom: FIT_PADDING + 160, left: FIT_PADDING },
      animated: true,
    });
  }, [fitKey, mappableProfiles, userCoordinates]);

  useEffect(() => {
    if (!focusProfileId || !mapRef.current) return;
    const profile = mappableProfiles.find((p) => profileKey(p) === focusProfileId);
    if (!profile || !isValidCoord(profile.coordinates)) return;

    mapRef.current.animateToRegion(
      {
        latitude: profile.coordinates[0],
        longitude: profile.coordinates[1],
        latitudeDelta: MARKER_FOCUS_DELTA,
        longitudeDelta: MARKER_FOCUS_DELTA,
      },
      850
    );
  }, [focusProfileId, mappableProfiles]);

  return (
    <MapView
      ref={mapRef}
      style={StyleSheet.absoluteFill}
      initialRegion={initialRegion}
      customMapStyle={Platform.OS === "android" && isDark ? mapDarkStyle : undefined}
      userInterfaceStyle={isDark ? "dark" : "light"}
      showsUserLocation={false}
      showsMyLocationButton={false}
      showsCompass={false}
      toolbarEnabled={false}
      rotateEnabled={false}
    >
      {userCoordinates && isValidCoord(userCoordinates) ? (
        <UserPin coordinates={userCoordinates} />
      ) : null}
      {mappableProfiles.map((profile) => (
        <PinMarker
          key={profileKey(profile)}
          profile={profile}
          onPress={() => onProfileFocus?.(profileKey(profile))}
        />
      ))}
    </MapView>
  );
}

const styles = StyleSheet.create({
  markerColumn: { alignItems: "center" },
  avatarRing: {
    width: 44,
    height: 44,
    borderRadius: 22,
    borderWidth: 2.5,
    borderColor: "#fff",
    overflow: "hidden",
    backgroundColor: "#25272b",
    shadowColor: "#000",
    shadowOpacity: 0.35,
    shadowRadius: 6,
    shadowOffset: { width: 0, height: 4 },
    elevation: 6,
  },
  avatar: { width: "100%", height: "100%" },
  distancePill: {
    marginTop: -4,
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 6,
    shadowColor: "#000",
    shadowOpacity: 0.2,
    shadowRadius: 4,
    shadowOffset: { width: 0, height: 2 },
    elevation: 3,
  },
  distanceText: {
    fontFamily: fonts.headlineMedium,
    fontSize: 10,
    fontWeight: "600",
  },
  dot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    borderWidth: 1,
    marginTop: 4,
  },
  userPin: {
    width: 64,
    height: 64,
    alignItems: "center",
    justifyContent: "center",
  },
  userPulseOuter: {
    position: "absolute",
    width: 56,
    height: 56,
    borderRadius: 28,
    backgroundColor: "rgba(10, 132, 255, 0.25)",
  },
  userPulseInner: {
    position: "absolute",
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: "rgba(10, 132, 255, 0.15)",
  },
  userDot: {
    width: 16,
    height: 16,
    borderRadius: 8,
    backgroundColor: "#0a84ff",
    borderWidth: 2.5,
    borderColor: "#fff",
  },
});
