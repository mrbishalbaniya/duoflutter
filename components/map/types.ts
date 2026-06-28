import type { Profile } from "@/types";

export type MapProfile = Profile & {
  coordinates: [number, number];
  browseOrder?: number;
  matchId?: number;
  distanceMeters: number;
};

export function profileKey(profile: Profile): string {
  return String(profile.user_id ?? profile.id ?? profile.full_name);
}
