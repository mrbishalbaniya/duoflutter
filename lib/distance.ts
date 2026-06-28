/** Great-circle distance in meters between two WGS84 points. */
export function haversineMeters(
  from: [number, number],
  to: [number, number]
): number {
  const [lat1, lon1] = from;
  const [lat2, lon2] = to;
  const R = 6371000;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLon / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

export function formatDistanceCompact(meters: number): string {
  if (!Number.isFinite(meters) || meters < 0) return "—";
  if (meters < 1000) return `${Math.max(1, Math.round(meters))} m`;
  const km = meters / 1000;
  return km < 10 ? `${km.toFixed(1)} km` : `${Math.round(km)} km`;
}

export function formatDistanceAway(meters: number): string {
  if (!Number.isFinite(meters) || meters < 0) return "Distance unknown";
  if (meters < 1000) {
    return `${Math.max(1, Math.round(meters))} m away from you`;
  }
  const km = meters / 1000;
  const label = km < 10 ? `${km.toFixed(1)} km` : `${Math.round(km)} km`;
  return `${label} away from you`;
}
