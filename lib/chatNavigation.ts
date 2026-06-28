export function chatPath(conversationId?: number | string | null) {
  if (conversationId != null && conversationId !== "") {
    return {
      pathname: "/(tabs)/chat" as const,
      params: { conversation: String(conversationId) },
    };
  }
  return "/(tabs)/chat" as const;
}

export function parseConversationId(value?: string | string[]): number | null {
  const raw = Array.isArray(value) ? value[0] : value;
  if (!raw) return null;
  const id = Number(raw);
  return Number.isFinite(id) && id > 0 ? id : null;
}
