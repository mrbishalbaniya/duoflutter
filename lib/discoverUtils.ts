import type { LikedProfile, SwipeAction } from "@/types";

export type DiscoverTab = "matches" | "liked-by-you" | "likes-you";

export const DISCOVER_TABS: { id: DiscoverTab; label: string }[] = [
  { id: "matches", label: "Matches" },
  { id: "liked-by-you", label: "Likes sent" },
  { id: "likes-you", label: "Liked you" },
];

export function likedProfileKey(item: LikedProfile): string {
  if (item.swipe_id != null) return `swipe-${item.swipe_id}`;
  const profileId = item.profile.user_id ?? item.profile.id;
  if (profileId != null) return String(profileId);
  return `${item.liked_at ?? "unknown"}-${item.action ?? "like"}`;
}

export function formatLikeTime(iso?: string): string {
  if (!iso) return "Recently";
  const date = new Date(iso);
  if (Number.isNaN(date.getTime())) return "Recently";

  const diffMs = Date.now() - date.getTime();
  const diffMins = Math.floor(diffMs / 60000);
  if (diffMins < 1) return "Just now";
  if (diffMins < 60) return `${diffMins}m ago`;

  const diffHours = Math.floor(diffMins / 60);
  if (diffHours < 24) return `${diffHours}h ago`;

  const diffDays = Math.floor(diffHours / 24);
  if (diffDays < 7) return `${diffDays}d ago`;

  return date.toLocaleDateString(undefined, { month: "short", day: "numeric" });
}

export function interactionTimeLabel(
  action: SwipeAction | undefined,
  kind: "matched" | "sent" | "received",
  time?: string
): string {
  const when = formatLikeTime(time);
  if (kind === "matched") return `Matched · ${when}`;
  if (kind === "sent") {
    if (action === "SUPERLIKE") return `Super like sent · ${when}`;
    return `Like sent · ${when}`;
  }
  if (action === "SUPERLIKE") return `Super like received · ${when}`;
  return `Like received · ${when}`;
}
