import * as Location from "expo-location";
import { useEffect, useState } from "react";
import { resolveProfileCoordinates } from "@/lib/locationCoords";

export function useUserCoordinates(
  profileLocation?: string,
  userId?: number | string
): [number, number] | null {
  const [coords, setCoords] = useState<[number, number] | null>(null);

  useEffect(() => {
    let cancelled = false;
    const fallback = resolveProfileCoordinates(profileLocation, userId);

    async function load() {
      try {
        const { status } = await Location.requestForegroundPermissionsAsync();
        if (status === "granted") {
          const position = await Location.getCurrentPositionAsync({
            accuracy: Location.Accuracy.Balanced,
          });
          if (!cancelled) {
            setCoords([position.coords.latitude, position.coords.longitude]);
            return;
          }
        }
      } catch {
        /* use profile city */
      }
      if (!cancelled) setCoords(fallback);
    }

    void load();
    return () => {
      cancelled = true;
    };
  }, [profileLocation, userId]);

  return coords;
}
