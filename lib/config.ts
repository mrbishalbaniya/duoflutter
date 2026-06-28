import Constants from "expo-constants";
import { Platform } from "react-native";

const extra = Constants.expoConfig?.extra as { apiUrl?: string } | undefined;
const DEFAULT_API = "http://localhost:8000/api";

function getMetroLanHost(): string | null {
  const hostUri = Constants.expoConfig?.hostUri;
  if (hostUri) {
    const host = hostUri.split(":")[0];
    if (host && host !== "localhost" && host !== "127.0.0.1") return host;
  }

  const match = Constants.linkingUri?.match(/^exp:\/\/([^:/]+)/);
  const host = match?.[1];
  if (host && host !== "localhost" && host !== "127.0.0.1") return host;

  return null;
}

function isLocalWebDev(): boolean {
  if (Platform.OS !== "web" || typeof window === "undefined") return false;
  const host = window.location.hostname;
  return host === "localhost" || host === "127.0.0.1";
}

function isProductionBuild(): boolean {
  return !__DEV__;
}

function resolveApiBase(): string {
  const fromEnv =
    process.env.EXPO_PUBLIC_API_URL?.replace(/\/$/, "") ||
    extra?.apiUrl?.replace(/\/$/, "") ||
    "";

  if (isProductionBuild() && !fromEnv) {
    throw new Error(
      "EXPO_PUBLIC_API_URL is required for production builds. Set it in .env or eas.json."
    );
  }

  const resolved = fromEnv || DEFAULT_API;

  if (isLocalWebDev()) {
    return DEFAULT_API;
  }

  if (Platform.OS === "web") return resolved;

  if (/localhost|127\.0\.0\.1/.test(resolved)) {
    const lanHost = getMetroLanHost();
    if (lanHost) {
      return resolved.replace(/localhost|127\.0\.0\.1/g, lanHost);
    }
    if (Platform.OS === "android") {
      return resolved.replace(/localhost|127\.0\.0\.1/g, "10.0.2.2");
    }
  }

  return resolved;
}

export const API_BASE = resolveApiBase();
export const API_ORIGIN = API_BASE.replace(/\/api\/?$/, "");

export function getGoogleClientId(): string | undefined {
  return process.env.EXPO_PUBLIC_GOOGLE_CLIENT_ID;
}
