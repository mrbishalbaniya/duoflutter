/** Subset of Google Maps dark style for Android. */
export const mapDarkStyle = [
  { elementType: "geometry", stylers: [{ color: "#1d1d1f" }] },
  { elementType: "labels.text.fill", stylers: [{ color: "#8a8a8e" }] },
  { elementType: "labels.text.stroke", stylers: [{ color: "#1d1d1f" }] },
  { featureType: "road", elementType: "geometry", stylers: [{ color: "#2c2c2e" }] },
  { featureType: "road", elementType: "geometry.stroke", stylers: [{ color: "#3a3a3c" }] },
  { featureType: "water", elementType: "geometry", stylers: [{ color: "#0e1014" }] },
  { featureType: "poi", elementType: "geometry", stylers: [{ color: "#242426" }] },
  { featureType: "transit", stylers: [{ visibility: "off" }] },
];
