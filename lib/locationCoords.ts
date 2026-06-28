export const NEPAL_CITY_COORDS: Record<string, [number, number]> = {
  kathmandu: [27.7172, 85.324],
  lalitpur: [27.6588, 85.3247],
  pokhara: [28.2096, 83.9856],
  bhaktapur: [27.671, 85.4298],
  chitwan: [27.5291, 84.3542],
  biratnagar: [26.4525, 87.2718],
  dharan: [26.8147, 87.2848],
  butwal: [27.7, 83.4483],
};

const DEFAULT_CENTER: [number, number] = [27.7172, 85.324];

function hashSeed(value: string): number {
  let hash = 0;
  for (let i = 0; i < value.length; i += 1) {
    hash = (hash << 5) - hash + value.charCodeAt(i);
    hash |= 0;
  }
  return Math.abs(hash);
}

export function findCityCenter(location: string): [number, number] {
  const normalized = location.toLowerCase();
  for (const [city, coords] of Object.entries(NEPAL_CITY_COORDS)) {
    if (normalized.includes(city)) return coords;
  }
  return DEFAULT_CENTER;
}

export function resolveProfileCoordinates(
  location: string | undefined,
  userId: number | string | undefined
): [number, number] {
  const base = findCityCenter(location?.trim() || "Kathmandu, Nepal");
  const seed = hashSeed(String(userId ?? location ?? "0"));
  const angle = (seed % 360) * (Math.PI / 180);
  const radius = 0.008 + (seed % 100) / 10000;
  return [
    base[0] + Math.cos(angle) * radius,
    base[1] + Math.sin(angle) * radius,
  ];
}

export const NEPAL_MAP_DEFAULT_CENTER = DEFAULT_CENTER;
