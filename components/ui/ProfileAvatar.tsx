import { Image, StyleSheet, View, type ImageStyle, type ViewStyle } from "react-native";
import { resolveProfilePhotoUrl } from "@/lib/mediaUrl";
import type { Profile } from "@/types";
import { colors, radius } from "@/constants/theme";

type Props = {
  profile: Partial<Profile>;
  size?: number;
  style?: ViewStyle;
  imageStyle?: ImageStyle;
};

export function ProfileAvatar({ profile, size = 56, style, imageStyle }: Props) {
  return (
    <View
      style={[
        styles.ring,
        { width: size, height: size, borderRadius: size / 2 },
        style,
      ]}
    >
      <Image
        source={{ uri: resolveProfilePhotoUrl(profile) }}
        style={[
          { width: size - 6, height: size - 6, borderRadius: (size - 6) / 2 },
          imageStyle,
        ]}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  ring: {
    borderWidth: 3,
    borderColor: colors.background,
    backgroundColor: colors.surfaceContainerHigh,
    alignItems: "center",
    justifyContent: "center",
    overflow: "hidden",
  },
});
