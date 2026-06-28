/** Duo design tokens — mirrored from DuoFrontend globals.css */
export const colors = {
  primary: "#e84a7a",
  primaryContainer: "#c83c67",
  accent: "#d4a574",
  love: "#ff4d6d",
  tertiary: "#8b5cf6",
  background: "#0f0f10",
  surface: "#17181a",
  surfaceContainer: "#1b1d20",
  surfaceContainerHigh: "#25272b",
  surfaceContainerHighest: "#2d3035",
  onSurface: "#ffffff",
  onSurfaceVariant: "#b0b3ba",
  border: "#2f3136",
  outlineVariant: "#374151",
  error: "#ef4444",
  success: "#34c759",
} as const;

export const lightColors = {
  ...colors,
  background: "#f7f7f8",
  surface: "#ffffff",
  surfaceContainer: "#ffffff",
  surfaceContainerHigh: "#eef0f2",
  surfaceContainerHighest: "#e5e7eb",
  onSurface: "#111827",
  onSurfaceVariant: "#4b5563",
  border: "#e5e7eb",
  outlineVariant: "#d1d5db",
} as const;

export const spacing = {
  xs: 4,
  sm: 8,
  md: 16,
  lg: 24,
  xl: 32,
  xxl: 48,
} as const;

export const radius = {
  md: 16,
  lg: 24,
  xl: 32,
  full: 9999,
} as const;

export const fonts = {
  headline: "PlusJakartaSans_700Bold",
  headlineMedium: "PlusJakartaSans_600SemiBold",
  body: "Inter_400Regular",
  bodyMedium: "Inter_500Medium",
} as const;
