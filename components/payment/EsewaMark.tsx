import { Image, StyleSheet } from "react-native";

const ESEWA_ICON_URL =
  "https://cdn.esewa.com.np/ui/images/logos/esewa-icon-large.png";

export function EsewaMark({ size = 24 }: { size?: number }) {
  return (
    <Image
      source={{ uri: ESEWA_ICON_URL }}
      style={{ width: size, height: size }}
      resizeMode="contain"
    />
  );
}

export const esewaMarkStyles = StyleSheet.create({});
