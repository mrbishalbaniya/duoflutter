import { Tabs, useGlobalSearchParams, useSegments } from "expo-router";
import { DuoTabBar } from "@/components/navigation/DuoTabBar";

export default function TabLayout() {
  const { conversation } = useGlobalSearchParams<{ conversation?: string }>();
  const segments = useSegments();
  const inChatThread = segments[1] === "chat" && Boolean(conversation);

  return (
    <Tabs
      tabBar={
        inChatThread
          ? () => null
          : (props) => <DuoTabBar state={props.state} navigation={props.navigation} />
      }
      screenOptions={{ headerShown: false, lazy: true }}
    >
      <Tabs.Screen name="discover" options={{ title: "Discover" }} />
      <Tabs.Screen name="chat" options={{ title: "Chat" }} />
      <Tabs.Screen name="match" options={{ title: "Match" }} />
      <Tabs.Screen name="map" options={{ title: "Map" }} />
      <Tabs.Screen name="profile" options={{ title: "Profile" }} />
    </Tabs>
  );
}
