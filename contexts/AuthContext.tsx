import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from "react";
import api from "@/lib/api";
import type { LoginResponse, RegisterResponse, User } from "@/types";

interface AuthContextValue {
  user: User | null;
  loading: boolean;
  login: (username: string, password: string) => Promise<LoginResponse>;
  loginWithGoogle: (idToken: string) => Promise<LoginResponse>;
  register: (email: string, password: string, full_name: string) => Promise<RegisterResponse>;
  logout: () => Promise<void>;
  fetchUser: () => Promise<void>;
}

const AuthContext = createContext<AuthContextValue | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  const fetchUser = useCallback(async () => {
    try {
      const token = await api.getToken();
      if (!token) {
        setUser(null);
        return;
      }
      const data = await api.getMe();
      setUser(data);
    } catch {
      setUser(null);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    api.setOnAuthFailed(() => setUser(null));

    const timeout = setTimeout(() => {
      setLoading(false);
    }, 8000);

    void fetchUser().finally(() => clearTimeout(timeout));

    return () => clearTimeout(timeout);
  }, [fetchUser]);

  const login = async (username: string, password: string) => {
    const data = await api.login(username, password);
    await fetchUser();
    return data;
  };

  const loginWithGoogle = async (idToken: string) => {
    const data = await api.loginWithGoogle(idToken);
    await fetchUser();
    return data;
  };

  const register = async (email: string, password: string, full_name: string) => {
    const data = await api.register(email, password, full_name);
    await fetchUser();
    return data;
  };

  const logout = async () => {
    await api.logout();
    setUser(null);
  };

  const value = useMemo(
    () => ({ user, loading, login, loginWithGoogle, register, logout, fetchUser }),
    [user, loading, fetchUser]
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within AuthProvider");
  return ctx;
}
