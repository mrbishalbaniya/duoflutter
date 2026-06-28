import type { Conversation, Message } from "@/types";

export function lastMessagePreview(convo: Conversation): string {
  const last = convo.last_message;
  if (typeof last === "string") return last;
  if (last && typeof last === "object") {
    return last.content || "Start the conversation!";
  }
  return "Start the conversation!";
}

export function getConversationLastActivity(convo: Conversation): string | undefined {
  if (convo.last_message_at) return convo.last_message_at;
  if (convo.updated_at) return convo.updated_at;
  const last = convo.last_message;
  if (last && typeof last === "object") {
    return last.timestamp || last.created_at;
  }
  return convo.created_at;
}

export function formatMessageTime(iso?: string): string {
  if (!iso) return "";
  try {
    const date = new Date(iso);
    if (Number.isNaN(date.getTime())) return "";

    const diff = Date.now() - date.getTime();
    const mins = Math.floor(diff / 60000);
    if (mins < 1) return "now";
    if (mins < 60) return `${mins}m`;
    const hours = Math.floor(mins / 60);
    if (hours < 24) return `${hours}h`;
    const days = Math.floor(hours / 24);
    if (days < 7) return `${days}d`;

    const now = new Date();
    if (date.getFullYear() === now.getFullYear()) {
      return date.toLocaleDateString(undefined, { month: "short", day: "numeric" });
    }
    return date.toLocaleDateString(undefined, {
      month: "short",
      day: "numeric",
      year: "2-digit",
    });
  } catch {
    return "";
  }
}

export function formatClockTime(iso?: string): string {
  if (!iso) return "";
  try {
    return new Date(iso).toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
  } catch {
    return "";
  }
}

export function sortConversations(conversations: Conversation[]): Conversation[] {
  return [...conversations].sort(
    (a, b) =>
      new Date(getConversationLastActivity(b) || 0).getTime() -
      new Date(getConversationLastActivity(a) || 0).getTime()
  );
}

export function normalizeMessages(messages: Message[]): Message[] {
  return [...messages].sort((a, b) => {
    const timeA = new Date(a.timestamp ?? a.created_at ?? 0).getTime();
    const timeB = new Date(b.timestamp ?? b.created_at ?? 0).getTime();
    if (timeA !== timeB) return timeA - timeB;
    return a.id - b.id;
  });
}

export function displayName(convo: Conversation): string {
  return convo.other_user_nickname?.trim() || convo.other_user_profile?.full_name || "Match";
}
