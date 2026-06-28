import { API_ORIGIN } from "@/lib/config";
import type { Profile } from "@/types";

const PLACEHOLDER =
  "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=600&h=800&fit=crop&q=80";

export function resolveMediaUrl(url?: string | null): string | undefined {
  if (!url) return undefined;
  if (url.startsWith("http://") || url.startsWith("https://")) return url;
  if (url.startsWith("/media/")) return `${API_ORIGIN}${url}`;
  return url;
}

export function resolveProfilePhotoUrl(profile: Partial<Profile>): string {
  return (
    resolveMediaUrl(profile.photo_url) ||
    resolveMediaUrl(profile.photo_urls?.find(Boolean)) ||
    PLACEHOLDER
  );
}
