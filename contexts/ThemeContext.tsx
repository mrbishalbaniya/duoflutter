import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from "react";
import { useColorScheme as useSystemScheme } from "react-native";
import { getItem, setItem } from "@/lib/storage";
import { colors, lightColors } from "@/constants/theme";
import type { ThemeMode } from "@/types";

const STORAGE_KEY = "duo_theme";

type ThemeColors = typeof colors | typeof lightColors;

type ThemeContextValue = {
  mode: ThemeMode;
  resolved: "dark" | "light";
  colors: ThemeColors;
  setMode: (mode: ThemeMode) => void;
};

const ThemeContext = createContext<ThemeContextValue | null>(null);

export function ThemeProvider({ children }: { children: ReactNode }) {
  const system = useSystemScheme();
  const [mode, setModeState] = useState<ThemeMode>("dark");

  useEffect(() => {
    void getItem(STORAGE_KEY).then((stored) => {
      if (stored === "light" || stored === "dark" || stored === "system") {
        setModeState(stored);
      }
    });
  }, []);

  const resolved: "dark" | "light" =
    mode === "system" ? (system === "light" ? "light" : "dark") : mode;

  const setMode = useCallback((next: ThemeMode) => {
    setModeState(next);
    void setItem(STORAGE_KEY, next);
  }, []);

  const value = useMemo(
    () => ({
      mode,
      resolved,
      colors: resolved === "light" ? lightColors : colors,
      setMode,
    }),
    [mode, resolved, setMode]
  );

  return <ThemeContext.Provider value={value}>{children}</ThemeContext.Provider>;
}

export function useTheme() {
  const ctx = useContext(ThemeContext);
  if (!ctx) throw new Error("useTheme must be used within ThemeProvider");
  return ctx;
}
