import type { ReactNode } from "react";
import { createElement } from "react";
import { Image, Platform, Pressable, StyleSheet, Text, View, type ImageStyle, type ViewStyle } from "react-native";
import { BlurView } from "expo-blur";
import { LinearGradient } from "expo-linear-gradient";
import { Ionicons } from "@expo/vector-icons";
import { resolveProfilePhotoUrl } from "@/lib/mediaUrl";
import type { Profile } from "@/types";
import { fonts } from "@/constants/theme";

type Props = {
  profile: Profile;
  timeLabel: string;
  locked?: boolean;
  onLockedPress?: () => void;
  actions?: ReactNode;
  style?: ViewStyle;
};

function LockedName({ name, ageText }: { name: string; ageText: string }) {
  if (Platform.OS === "web") {
    return (
      <View style={styles.lockedNameRow}>
        {createElement(
          "span",
          {
            style: {
              display: "inline-block",
              color: "#fff",
              fontFamily: fonts.headlineMedium,
              fontSize: 16,
              fontWeight: "600",
              lineHeight: "20px",
              maxWidth: "72%",
              overflow: "hidden",
              textOverflow: "ellipsis",
              whiteSpace: "nowrap",
              verticalAlign: "bottom",
              filter: "blur(5px)",
              WebkitFilter: "blur(5px)",
              userSelect: "none",
            },
          },
          name
        )}
        {ageText ? <Text style={styles.name}>{ageText}</Text> : null}
      </View>
    );
  }

  return (
    <View style={styles.lockedNameRow}>
      <View style={styles.lockedNameWrap}>
        <Text style={styles.name} numberOfLines={1}>
          {name}
        </Text>
        <BlurView intensity={28} tint="dark" style={StyleSheet.absoluteFillObject} />
      </View>
      {ageText ? <Text style={styles.name}>{ageText}</Text> : null}
    </View>
  );
}

export function DiscoverProfileCard({
  profile,
  timeLabel,
  locked = false,
  onLockedPress,
  actions,
  style,
}: Props) {
  const name = profile.full_name || "Duo member";
  const ageText = profile.age != null ? `, ${profile.age}` : "";
  const photoUrl = resolveProfilePhotoUrl(profile);
  const distanceLabel =
    profile.preview_distance_km != null ? `${profile.preview_distance_km} km` : "Nearby";

  const body = (
    <>
      <View style={styles.photoWrap}>
        {photoUrl ? (
          <View style={styles.photoClip}>
            <Image
              source={{ uri: photoUrl }}
              style={[
                styles.photo,
                locked && Platform.OS === "web" ? styles.webPhotoBlur : null,
              ]}
              blurRadius={locked && Platform.OS !== "web" ? 16 : 0}
            />
            {locked && Platform.OS !== "web" ? (
              <BlurView intensity={18} tint="dark" style={StyleSheet.absoluteFillObject} />
            ) : null}
          </View>
        ) : (
          <View style={styles.photoFallback}>
            <Ionicons name="person" size={48} color="rgba(255,255,255,0.15)" />
          </View>
        )}
        <LinearGradient
          colors={["transparent", "rgba(0,0,0,0.15)", "rgba(0,0,0,0.9)"]}
          style={styles.gradient}
        />
        <View style={styles.caption}>
          {locked ? (
            <>
              <LockedName name={name} ageText={ageText} />
              <Text style={styles.meta}>{distanceLabel}</Text>
            </>
          ) : (
            <>
              <Text style={styles.name} numberOfLines={1}>
                {name}
                {ageText}
              </Text>
              <Text style={styles.meta} numberOfLines={1}>
                {timeLabel}
              </Text>
            </>
          )}
        </View>
      </View>
      {actions ? <View style={styles.actions}>{actions}</View> : null}
    </>
  );

  if (locked && onLockedPress) {
    return (
      <Pressable onPress={onLockedPress} style={[styles.card, style]}>
        {body}
      </Pressable>
    );
  }

  return <View style={[styles.card, style]}>{body}</View>;
}

const styles = StyleSheet.create({
  card: {
    flex: 1,
    borderRadius: 20,
    overflow: "hidden",
    backgroundColor: "#25272b",
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: "rgba(255,255,255,0.08)",
    minWidth: 0,
  },
  photoWrap: {
    aspectRatio: 3 / 4,
    width: "100%",
    backgroundColor: "#17171a",
  },
  photoClip: {
    width: "100%",
    height: "100%",
    overflow: "hidden",
  },
  webPhotoBlur: {
    filter: "blur(8px)",
    WebkitFilter: "blur(8px)",
  } as ImageStyle,
  photo: { width: "100%", height: "100%" },
  photoFallback: {
    flex: 1,
    alignItems: "center",
    justifyContent: "center",
    backgroundColor: "#2a2a2e",
  },
  gradient: {
    ...StyleSheet.absoluteFillObject,
  },
  caption: {
    position: "absolute",
    left: 0,
    right: 0,
    bottom: 0,
    padding: 12,
  },
  lockedNameRow: {
    flexDirection: "row",
    alignItems: "center",
    flexWrap: "wrap",
    gap: 0,
  },
  lockedNameWrap: {
    overflow: "hidden",
    borderRadius: 4,
    maxWidth: "72%",
    marginRight: 2,
  },
  name: {
    color: "#fff",
    fontFamily: fonts.headlineMedium,
    fontSize: 16,
  },
  meta: {
    color: "rgba(255,255,255,0.75)",
    fontFamily: fonts.body,
    fontSize: 12,
    marginTop: 4,
  },
  actions: {
    flexDirection: "row",
    alignItems: "center",
    gap: 8,
    minHeight: 52,
    padding: 10,
  },
});
