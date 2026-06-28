import * as WebBrowser from "expo-web-browser";
import * as Google from "expo-auth-session/providers/google";
import { Platform } from "react-native";
import { getGoogleClientId } from "@/lib/config";

WebBrowser.maybeCompleteAuthSession();

export function useGoogleSignIn() {
  const clientId = getGoogleClientId();

  const [request, response, promptAsync] = Google.useIdTokenAuthRequest({
    clientId: clientId ?? "",
  });

  const idToken = response?.type === "success" ? response.params.id_token : undefined;

  return {
    clientId,
    request,
    response,
    idToken,
    promptAsync,
    isReady: Boolean(clientId && request),
  };
}

export function getGoogleSignInHint(): string | null {
  if (getGoogleClientId()) return null;
  if (Platform.OS === "web") {
    return "Set EXPO_PUBLIC_GOOGLE_CLIENT_ID in .env for Google sign-in.";
  }
  return "Google sign-in is not configured.";
}
