import { Redirect, useLocalSearchParams } from "expo-router";
import { chatPath } from "@/lib/chatNavigation";

/** Legacy `/chat/:id` URLs → `/chat?conversation=:id` */
export default function ChatLegacyRedirect() {
  const { id } = useLocalSearchParams<{ id: string }>();
  return <Redirect href={chatPath(id)} />;
}
