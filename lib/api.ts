import { getItem, setItem, deleteItem } from "@/lib/storage";
import { API_BASE } from "@/lib/config";
import type {
  Conversation,
  InitiateSubscriptionResponse,
  LoginResponse,
  Match,
  LikedProfile,
  LikesYouResponse,
  Message,
  Profile,
  RegisterResponse,
  SubscriptionPlan,
  SwipeAction,
  SwipeResponse,
  User,
  VerificationStartResponse,
  VerificationStatusResponse,
} from "@/types";

const ACCESS_KEY = "duo_access_token";
const REFRESH_KEY = "duo_refresh_token";

type RequestOptions = RequestInit & { headers?: Record<string, string> };

class ApiClient {
  private baseUrl = API_BASE;
  private memoryAccess: string | null = null;
  private memoryRefresh: string | null = null;
  private onAuthFailed?: () => void;

  setOnAuthFailed(handler: () => void) {
    this.onAuthFailed = handler;
  }

  async getToken(): Promise<string | null> {
    if (this.memoryAccess) return this.memoryAccess;
    this.memoryAccess = await getItem(ACCESS_KEY);
    return this.memoryAccess;
  }

  async setTokens(access: string, refresh: string): Promise<void> {
    this.memoryAccess = access;
    this.memoryRefresh = refresh;
    await setItem(ACCESS_KEY, access);
    await setItem(REFRESH_KEY, refresh);
  }

  async clearTokens(): Promise<void> {
    this.memoryAccess = null;
    this.memoryRefresh = null;
    await deleteItem(ACCESS_KEY);
    await deleteItem(REFRESH_KEY);
  }

  async logout(): Promise<void> {
    const token = await this.getToken();
    try {
      if (token) {
        await fetch(`${this.baseUrl}/auth/logout/`, {
          method: "POST",
          headers: { Authorization: `Bearer ${token}` },
        });
      }
    } catch {
      // Best-effort server logout
    }
    await this.clearTokens();
  }

  private async refreshToken(): Promise<boolean> {
    const refresh =
      this.memoryRefresh ?? (await getItem(REFRESH_KEY));
    if (!refresh) return false;
    try {
      const res = await fetch(`${this.baseUrl}/auth/refresh/`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ refresh }),
      });
      if (!res.ok) return false;
      const data = (await res.json()) as { access: string };
      this.memoryAccess = data.access;
      await setItem(ACCESS_KEY, data.access);
      return true;
    } catch {
      return false;
    }
  }

  async request<T>(endpoint: string, options: RequestOptions = {}): Promise<T> {
    const token = await this.getToken();
    const headers: Record<string, string> = {
      "Content-Type": "application/json",
    };
    if (token) headers.Authorization = `Bearer ${token}`;
    if (options.headers) {
      Object.assign(headers, options.headers as Record<string, string>);
    }

    const res = await fetch(`${this.baseUrl}${endpoint}`, { ...options, headers });

    if (res.status === 401) {
      const refreshed = await this.refreshToken();
      if (refreshed) {
        headers.Authorization = `Bearer ${await this.getToken()}`;
        const retry = await fetch(`${this.baseUrl}${endpoint}`, { ...options, headers });
        if (!retry.ok) throw new Error(`API Error: ${retry.status}`);
        return retry.json() as Promise<T>;
      }
      await this.clearTokens();
      this.onAuthFailed?.();
      throw new Error("Authentication failed");
    }

    if (!res.ok) {
      const text = await res.text();
      let detail = `API Error: ${res.status}`;
      try {
        const data = JSON.parse(text) as Record<string, unknown>;
        if (typeof data.detail === "string") detail = data.detail;
      } catch {
        if (text) detail = text.slice(0, 200);
      }
      throw new Error(detail);
    }

    return res.json() as Promise<T>;
  }

  async login(username: string, password: string): Promise<LoginResponse> {
    let res: Response;
    try {
      res = await fetch(`${this.baseUrl}/auth/login/`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ username, password }),
      });
    } catch {
      throw new Error(
        `Cannot reach the API at ${this.baseUrl}. Is DuoBackend running? (python manage.py runserver)`
      );
    }
    if (!res.ok) throw new Error("Invalid email or password");
    const data = (await res.json()) as LoginResponse;
    await this.setTokens(data.access, data.refresh);
    return data;
  }

  async loginWithGoogle(idToken: string): Promise<LoginResponse> {
    let res: Response;
    try {
      res = await fetch(`${this.baseUrl}/auth/google/`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ id_token: idToken }),
      });
    } catch {
      throw new Error(`Cannot reach the API at ${this.baseUrl}.`);
    }
    if (!res.ok) {
      const data = (await res.json().catch(() => ({}))) as { detail?: string };
      throw new Error(data.detail ?? "Google sign-in failed");
    }
    const data = (await res.json()) as LoginResponse;
    await this.setTokens(data.access, data.refresh);
    return data;
  }

  async register(email: string, password: string, full_name: string): Promise<RegisterResponse> {
    const data = await this.request<RegisterResponse>("/auth/register/", {
      method: "POST",
      body: JSON.stringify({ email, password, full_name }),
    });
    await this.setTokens(data.tokens.access, data.tokens.refresh);
    return data;
  }

  async getMe(): Promise<User> {
    return this.request<User>("/auth/me/");
  }

  async getMyProfile(): Promise<Profile> {
    return this.request<Profile>("/profiles/me/");
  }

  async updateProfile(data: Partial<Profile>): Promise<Profile> {
    return this.request<Profile>("/profiles/me/", {
      method: "PUT",
      body: JSON.stringify(data),
    });
  }

  async changePassword(currentPassword: string, newPassword: string) {
    return this.request<{ message: string }>("/auth/password/change/", {
      method: "POST",
      body: JSON.stringify({ current_password: currentPassword, new_password: newPassword }),
    });
  }

  async discoverProfiles(): Promise<Profile[]> {
    return this.request<Profile[]>("/profiles/discover/");
  }

  async swipe(toUserId: number, action: SwipeAction): Promise<SwipeResponse> {
    return this.request<SwipeResponse>("/matching/swipe/", {
      method: "POST",
      body: JSON.stringify({ to_user_id: toUserId, action }),
    });
  }

  async getMatches(): Promise<Match[]> {
    return this.request<Match[]>("/matching/matches/");
  }

  async getLikedByYou(): Promise<LikedProfile[]> {
    return this.request<LikedProfile[]>("/matching/liked-by-you/");
  }

  async getLikesYou(): Promise<LikesYouResponse> {
    return this.request<LikesYouResponse>("/matching/likes-you/");
  }

  async getConversations(): Promise<Conversation[]> {
    return this.request<Conversation[]>("/chat/conversations/");
  }

  async getMessages(conversationId: number): Promise<Message[]> {
    return this.request<Message[]>(`/chat/conversations/${conversationId}/messages/`);
  }

  async sendMessage(conversationId: number, content: string, image_url = ""): Promise<Message> {
    return this.request<Message>(`/chat/conversations/${conversationId}/messages/`, {
      method: "POST",
      body: JSON.stringify({ content, image_url }),
    });
  }

  async getWsTicket(conversationId: number): Promise<string> {
    const data = await this.request<{ ticket: string }>(
      `/chat/conversations/${conversationId}/ws-ticket/`,
      { method: "POST" }
    );
    return data.ticket;
  }

  async sendTypingHeartbeat(conversationId: number): Promise<void> {
    await this.request(`/chat/conversations/${conversationId}/typing/`, { method: "POST" });
  }

  async startVerification(): Promise<VerificationStartResponse> {
    return this.request<VerificationStartResponse>("/verification/start/", { method: "POST" });
  }

  async getVerificationStatus(): Promise<VerificationStatusResponse> {
    return this.request<VerificationStatusResponse>("/verification/status/");
  }

  async getSubscriptionPlans(): Promise<SubscriptionPlan[]> {
    return this.request<SubscriptionPlan[]>("/subscriptions/plan/");
  }

  async initiateSubscription(planId: string): Promise<InitiateSubscriptionResponse> {
    return this.request<InitiateSubscriptionResponse>("/subscriptions/initiate/", {
      method: "POST",
      body: JSON.stringify({ plan_id: planId }),
    });
  }
}

const api = new ApiClient();
export default api;
