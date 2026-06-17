function readRequiredEnv(name: string): string {
  const value = import.meta.env[name];

  if (!value || typeof value !== "string" || value.trim() === "") {
    throw new Error(`Missing required environment variable: ${name}`);
  }

  return value.trim();
}

function readOptionalEnv(name: string, fallback: string): string {
  const value = import.meta.env[name];

  if (!value || typeof value !== "string" || value.trim() === "") {
    return fallback;
  }

  return value.trim();
}

export const authConfig = {
  apiBaseUrl: readOptionalEnv("VITE_API_BASE_URL", ""),
  cognitoBaseUrl: readRequiredEnv("VITE_COGNITO_BASE_URL"),
  clientId: readRequiredEnv("VITE_COGNITO_CLIENT_ID"),
  redirectUri: readRequiredEnv("VITE_COGNITO_REDIRECT_URI"),
  logoutUri: readRequiredEnv("VITE_COGNITO_LOGOUT_URI"),
  scope: readOptionalEnv("VITE_COGNITO_SCOPE", "openid email profile"),
};

export const authEndpoints = {
  authorize: `${authConfig.cognitoBaseUrl}/oauth2/authorize`,
  token: `${authConfig.cognitoBaseUrl}/oauth2/token`,
  logout: `${authConfig.cognitoBaseUrl}/logout`,
};
