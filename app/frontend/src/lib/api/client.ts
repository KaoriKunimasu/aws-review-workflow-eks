const apiBaseUrl = import.meta.env.VITE_API_BASE_URL;

if (!apiBaseUrl) {
  throw new Error("VITE_API_BASE_URL is not set.");
}

type ApiFetchOptions = {
  method?: "GET" | "POST" | "PUT" | "PATCH" | "DELETE";
  userId?: string;
  body?: unknown;
  signal?: AbortSignal;
};

export class ApiError extends Error {
  status: number;
  details: unknown;

  constructor(message: string, status: number, details: unknown) {
    super(message);
    this.name = "ApiError";
    this.status = status;
    this.details = details;
  }
}

function buildUrl(path: string): string {
  const normalizedBaseUrl = apiBaseUrl.endsWith("/")
    ? apiBaseUrl.slice(0, -1)
    : apiBaseUrl;

  const normalizedPath = path.startsWith("/") ? path : `/${path}`;

  return `${normalizedBaseUrl}${normalizedPath}`;
}

async function parseResponseBody(response: Response): Promise<unknown> {
  const text = await response.text();

  if (!text) {
    return null;
  }

  try {
    return JSON.parse(text);
  } catch {
    return text;
  }
}

function getErrorMessage(details: unknown, fallbackMessage: string): string {
  if (typeof details === "string" && details.trim().length > 0) {
    return details;
  }

  if (details && typeof details === "object") {
    const record = details as Record<string, unknown>;

    if (typeof record.message === "string" && record.message.trim().length > 0) {
      return record.message;
    }

    if (typeof record.error === "string" && record.error.trim().length > 0) {
      return record.error;
    }
  }

  return fallbackMessage;
}

export async function apiFetch<T>(
  path: string,
  options: ApiFetchOptions = {},
): Promise<T> {
  const { method = "GET", userId, body, signal } = options;

  const headers: HeadersInit = {
    Accept: "application/json",
  };

  if (body !== undefined) {
    headers["Content-Type"] = "application/json";
  }

  if (userId) {
    headers["X-User-Id"] = userId;
  }

  const response = await fetch(buildUrl(path), {
    method,
    headers,
    body: body !== undefined ? JSON.stringify(body) : undefined,
    signal,
  });

  const details = await parseResponseBody(response);

  if (!response.ok) {
    throw new ApiError(
      getErrorMessage(details, `API request failed with status ${response.status}.`),
      response.status,
      details,
    );
  }

  return details as T;
}
