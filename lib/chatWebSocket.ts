import { API_ORIGIN } from "@/lib/config";

export function getChatWebSocketUrl(conversationId: number | string, ticket: string): string {
  const url = new URL(`/ws/chat/${conversationId}/`, API_ORIGIN);
  url.protocol = url.protocol === "https:" ? "wss:" : "ws:";
  url.searchParams.set("ticket", ticket);
  return url.toString();
}

export function closeChatSocket(socket: WebSocket | null, reason = "cleanup") {
  if (!socket) return;

  if (socket.readyState === WebSocket.CONNECTING) {
    socket.addEventListener(
      "open",
      () => {
        socket.close(1000, reason);
      },
      { once: true }
    );
    return;
  }

  if (socket.readyState === WebSocket.OPEN) {
    socket.close(1000, reason);
  }
}

export type ChatWsEvent =
  | { type: "chat_message"; id: number; sender_id: number; content: string; image_url?: string; sender_name: string; timestamp: string }
  | { type: "typing_status"; user_id: number; is_typing: boolean }
  | { type: "message_deleted"; id: number; user_id: number; delete_type: string };
