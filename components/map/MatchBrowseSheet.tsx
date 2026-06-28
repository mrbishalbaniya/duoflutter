import { useCallback, useEffect, useMemo, useState, type ReactNode } from "react";
import {
  Dimensions,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from "react-native";
import Animated, {
  runOnJS,
  useAnimatedStyle,
  useSharedValue,
  withSpring,
} from "react-native-reanimated";
import { Gesture, GestureDetector } from "react-native-gesture-handler";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { useTheme } from "@/contexts/ThemeContext";
import { fonts, radius, spacing } from "@/constants/theme";

export type MatchBrowseSheetSnap = "map" | "list";

const PEEK_HEIGHT = 128;
const { height: SCREEN_HEIGHT } = Dimensions.get("window");

type Props = {
  snap: MatchBrowseSheetSnap;
  onSnapChange: (snap: MatchBrowseSheetSnap) => void;
  matchCount: number;
  hidden?: boolean;
  children: ReactNode;
};

export function MatchBrowseSheet({
  snap,
  onSnapChange,
  matchCount,
  hidden = false,
  children,
}: Props) {
  const { colors, resolved } = useTheme();
  const isDark = resolved === "dark";
  const insets = useSafeAreaInsets();
  const sheetHeight = Math.max(300, Math.round(SCREEN_HEIGHT * 0.88));
  const collapsedY = Math.max(0, sheetHeight - PEEK_HEIGHT);
  const translateY = useSharedValue(snap === "map" ? collapsedY : 0);
  const startY = useSharedValue(0);

  useEffect(() => {
    translateY.value = withSpring(snap === "map" ? collapsedY : 0, {
      damping: 32,
      stiffness: 380,
      mass: 0.85,
    });
  }, [snap, collapsedY, translateY]);

  const setSnap = useCallback(
    (next: MatchBrowseSheetSnap) => onSnapChange(next),
    [onSnapChange]
  );

  const pan = Gesture.Pan()
    .onBegin(() => {
      startY.value = translateY.value;
    })
    .onUpdate((e) => {
      const next = startY.value + e.translationY;
      translateY.value = Math.min(collapsedY, Math.max(0, next));
    })
    .onEnd((e) => {
      const current = translateY.value;
      const mid = collapsedY * 0.42;
      if (e.velocityY > 400 || current > mid) {
        translateY.value = withSpring(collapsedY, { damping: 32, stiffness: 380 });
        runOnJS(setSnap)("map");
        return;
      }
      if (e.velocityY < -400 || current < mid) {
        translateY.value = withSpring(0, { damping: 32, stiffness: 380 });
        runOnJS(setSnap)("list");
        return;
      }
      const nextSnap = current > mid ? "map" : "list";
      translateY.value = withSpring(nextSnap === "map" ? collapsedY : 0, {
        damping: 32,
        stiffness: 380,
      });
      runOnJS(setSnap)(nextSnap);
    });

  const sheetStyle = useAnimatedStyle(() => ({
    transform: [{ translateY: translateY.value }],
  }));

  if (hidden) return null;

  const glassBg = isDark ? "rgba(27, 29, 32, 0.92)" : "rgba(255, 255, 255, 0.92)";

  return (
    <View style={styles.overlay} pointerEvents="box-none">
      <GestureDetector gesture={pan}>
        <Animated.View
          style={[
            styles.sheet,
            {
              height: sheetHeight,
              backgroundColor: glassBg,
              borderColor: colors.border,
              paddingBottom: Math.max(insets.bottom, spacing.md),
            },
            sheetStyle,
          ]}
        >
          <View style={styles.handleArea}>
            <View style={[styles.handle, { backgroundColor: colors.onSurfaceVariant + "40" }]} />
            <Text style={[styles.subtitle, { color: colors.onSurfaceVariant }]}>
              {matchCount} {matchCount === 1 ? "friend" : "friends"} nearby
            </Text>
          </View>

          <View style={[styles.segmented, { backgroundColor: colors.surfaceContainerHigh }]}>
            <Pressable
              onPress={() => onSnapChange("map")}
              style={[
                styles.segmentBtn,
                snap === "map" && { backgroundColor: colors.surfaceContainerHighest },
              ]}
            >
              <Text
                style={[
                  styles.segmentText,
                  { color: snap === "map" ? colors.onSurface : colors.onSurfaceVariant },
                ]}
              >
                Map
              </Text>
            </Pressable>
            <Pressable
              onPress={() => onSnapChange("list")}
              style={[
                styles.segmentBtn,
                snap === "list" && { backgroundColor: colors.surfaceContainerHighest },
              ]}
            >
              <Text
                style={[
                  styles.segmentText,
                  { color: snap === "list" ? colors.onSurface : colors.onSurfaceVariant },
                ]}
              >
                List
              </Text>
            </Pressable>
          </View>

          <ScrollView
            style={styles.list}
            contentContainerStyle={styles.listContent}
            showsVerticalScrollIndicator={false}
            nestedScrollEnabled
          >
            {children}
          </ScrollView>
        </Animated.View>
      </GestureDetector>
    </View>
  );
}

const styles = StyleSheet.create({
  overlay: {
    ...StyleSheet.absoluteFill,
    justifyContent: "flex-end",
    zIndex: 35,
  },
  sheet: {
    borderTopLeftRadius: 20,
    borderTopRightRadius: 20,
    borderTopWidth: StyleSheet.hairlineWidth,
    overflow: "hidden",
  },
  handleArea: { alignItems: "center", paddingTop: 10, paddingBottom: 8 },
  handle: { width: 36, height: 5, borderRadius: 999, marginBottom: 8 },
  subtitle: { fontFamily: fonts.headlineMedium, fontSize: 13 },
  segmented: {
    flexDirection: "row",
    marginHorizontal: spacing.md,
    marginBottom: spacing.sm,
    borderRadius: radius.md,
    padding: 4,
  },
  segmentBtn: {
    flex: 1,
    alignItems: "center",
    paddingVertical: 8,
    borderRadius: 12,
  },
  segmentText: { fontFamily: fonts.headlineMedium, fontSize: 14 },
  list: { flex: 1 },
  listContent: { paddingBottom: spacing.lg },
});
