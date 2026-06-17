import { useNavigate } from "react-router-dom";

import { useAuth } from "../app/providers/AuthProvider";

export function LoginPage() {
  const navigate = useNavigate();
  const { isAuthenticated, isLoading, login, logout } = useAuth();

  return (
    <main style={{ padding: "2rem", maxWidth: "560px", margin: "0 auto" }}>
      <h1>AWS Serverless Review Workflow</h1>
      <p>
        Sign in with Amazon Cognito to access the review workflow application.
      </p>

      {isAuthenticated ? (
        <div style={{ display: "grid", gap: "0.75rem", marginTop: "1.5rem" }}>
          <button type="button" onClick={() => navigate("/dashboard")}>
            Continue to dashboard
          </button>
          <button type="button" onClick={logout}>
            Sign out
          </button>
        </div>
      ) : (
        <div style={{ display: "grid", gap: "0.75rem", marginTop: "1.5rem" }}>
          <button type="button" onClick={() => void login()} disabled={isLoading}>
            Sign in with Cognito
          </button>
        </div>
      )}
    </main>
  );
}
