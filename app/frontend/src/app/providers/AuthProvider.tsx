import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from "react";

import {
  completeHostedUiLogin,
  getStoredSession,
  logoutFromHostedUi,
  startHostedUiLogin,
  type AuthSession,
} from "../../lib/auth/session";

type AuthContextValue = {
  session: AuthSession | null;
  claims: Record<string, unknown>;
  isAuthenticated: boolean;
  isLoading: boolean;
  login: () => Promise<void>;
  logout: () => void;
  completeLogin: (code: string, state: string) => Promise<void>;
};

const AuthContext = createContext<AuthContextValue | undefined>(undefined);

type AuthProviderProps = {
  children: ReactNode;
};

export function AuthProvider({ children }: AuthProviderProps) {
  const [session, setSession] = useState<AuthSession | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const storedSession = getStoredSession();
    setSession(storedSession);
    setIsLoading(false);
  }, []);

  const login = useCallback(async () => {
    await startHostedUiLogin();
  }, []);

  const logout = useCallback(() => {
    setSession(null);
    logoutFromHostedUi();
  }, []);

  const completeLogin = useCallback(async (code: string, state: string) => {
    setIsLoading(true);

    try {
      const nextSession = await completeHostedUiLogin({ code, state });
      setSession(nextSession);
    } finally {
      setIsLoading(false);
    }
  }, []);

  const value = useMemo<AuthContextValue>(
    () => ({
      session,
      claims: session?.claims ?? {},
      isAuthenticated: session !== null,
      isLoading,
      login,
      logout,
      completeLogin,
    }),
    [completeLogin, isLoading, login, logout, session],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthContextValue {
  const value = useContext(AuthContext);

  if (!value) {
    throw new Error("useAuth must be used within an AuthProvider.");
  }

  return value;
}
