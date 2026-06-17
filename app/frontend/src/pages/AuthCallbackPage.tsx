import { useEffect, useRef, useState } from "react";
import { useNavigate, useSearchParams } from "react-router-dom";

import { useAuth } from "../app/providers/AuthProvider";

export function AuthCallbackPage() {
  const { completeLogin } = useAuth();
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const startedRef = useRef(false);

  useEffect(() => {
    if (startedRef.current) {
      return;
    }

    startedRef.current = true;

    const code = searchParams.get("code");
    const state = searchParams.get("state");
    const error = searchParams.get("error");
    const errorDescription = searchParams.get("error_description");

    if (error) {
      setErrorMessage(errorDescription || error);
      return;
    }

    if (!code || !state) {
      setErrorMessage("Missing authorization code or state.");
      return;
    }

    completeLogin(code, state)
      .then(() => {
        navigate("/dashboard", { replace: true });
      })
      .catch((authError: unknown) => {
        const message =
          authError instanceof Error
            ? authError.message
            : "Failed to complete sign-in.";

        setErrorMessage(message);
      });
  }, [completeLogin, navigate, searchParams]);

  return (
    <main style={{ padding: "2rem" }}>
      <h1>Signing you in</h1>
      {errorMessage ? (
        <p style={{ color: "#b00020" }}>{errorMessage}</p>
      ) : (
        <p>Completing the sign-in flow...</p>
      )}
    </main>
  );
}
