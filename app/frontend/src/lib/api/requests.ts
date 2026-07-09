import type { ListRequestsResponse, WorkflowRequest } from "../../types/request";
import { apiFetch } from "./client";

export type RequestStatus = "OPEN" | "IN_REVIEW" | "APPROVED" | "REJECTED";

export type CreateRequestPayload = {
  title: string;
  requestType: string;
  sourceLanguage: string;
  targetLanguage: string;
  sourceText: string;
  targetText?: string;
  category?: string;
  reviewerNote?: string;
};

export type RequestDetail = {
  requestId: string;
  title: string;
  requestType: string;
  sourceLanguage: string;
  targetLanguage: string;
  sourceText: string;
  targetText: string;
  category: string;
  status: string;
  reviewerNote: string;
  createdBy: string;
  createdAt: string;
  updatedAt: string;
};

export type CreateRequestResponse = {
  item: RequestDetail;
  message?: string;
};

export type UpdateRequestStatusPayload = {
  status: RequestStatus;
  reviewerNote?: string;
};

export type UpdateRequestStatusResponse = {
  item: RequestDetail;
  message?: string;
};

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null;
}

function readString(value: unknown, fallback = ""): string {
  return typeof value === "string" ? value : fallback;
}

function readOptionalString(value: unknown): string | undefined {
  return typeof value === "string" && value.length > 0 ? value : undefined;
}

function readBoolean(value: unknown, fallback = false): boolean {
  return typeof value === "boolean" ? value : fallback;
}

function readNumber(value: unknown, fallback: number): number {
  return typeof value === "number" ? value : fallback;
}

function normalizeListItem(value: unknown): WorkflowRequest {
  const source = isRecord(value) ? value : {};

  return {
    requestId: readString(source.requestId, "unknown-request-id"),
    title: readString(source.title, "Untitled request"),
    description: readString(source.sourceText, ""),
    sourceLanguage: readString(source.sourceLanguage, "ja"),
    targetLanguage: readString(source.targetLanguage, "en"),
    status: readOptionalString(source.status),
    createdAt: readString(source.createdAt, new Date(0).toISOString()),
    createdBy: readOptionalString(source.createdBy),
  };
}

function normalizeDetail(value: unknown): RequestDetail {
  const source = isRecord(value) ? value : {};

  return {
    requestId: readString(source.requestId, "unknown-request-id"),
    title: readString(source.title, "Untitled request"),
    requestType: readString(source.requestType),
    sourceLanguage: readString(source.sourceLanguage),
    targetLanguage: readString(source.targetLanguage),
    sourceText: readString(source.sourceText),
    targetText: readString(source.targetText),
    category: readString(source.category),
    status: readString(source.status, "OPEN"),
    reviewerNote: readString(source.reviewerNote),
    createdBy: readString(source.createdBy),
    createdAt: readString(source.createdAt, new Date(0).toISOString()),
    updatedAt: readString(source.updatedAt, new Date(0).toISOString()),
  };
}

function normalizeListResponse(value: unknown): ListRequestsResponse {
  if (Array.isArray(value)) {
    const items = value.map(normalizeListItem);

    return {
      items,
      count: items.length,
      hasMore: false,
    };
  }

  if (isRecord(value)) {
    const rawItems = Array.isArray(value.items) ? value.items : [];
    const items = rawItems.map(normalizeListItem);

    return {
      items,
      count: readNumber(value.count, items.length),
      hasMore: readBoolean(value.hasMore, false),
      cursor: readOptionalString(value.cursor),
    };
  }

  return {
    items: [],
    count: 0,
    hasMore: false,
  };
}

function normalizeCreateResponse(value: unknown): CreateRequestResponse {
  if (isRecord(value) && value.item) {
    return {
      item: normalizeDetail(value.item),
      message: readOptionalString(value.message),
    };
  }

  return {
    item: normalizeDetail(value),
  };
}

function normalizeDetailResponse(value: unknown): RequestDetail {
  if (isRecord(value) && value.item) {
    return normalizeDetail(value.item);
  }

  return normalizeDetail(value);
}

function normalizeUpdateResponse(value: unknown): UpdateRequestStatusResponse {
  if (isRecord(value) && value.item) {
    return {
      item: normalizeDetail(value.item),
      message: readOptionalString(value.message),
    };
  }

  return {
    item: normalizeDetail(value),
  };
}

export async function listRequests(
  userId: string,
): Promise<ListRequestsResponse> {
  const response = await apiFetch<unknown>("/reviews", {
    method: "GET",
    userId,
  });

  return normalizeListResponse(response);
}

export async function createRequest(
  userId: string,
  payload: CreateRequestPayload,
): Promise<CreateRequestResponse> {
  const response = await apiFetch<unknown>("/reviews", {
    method: "POST",
    userId,
    body: payload,
  });

  return normalizeCreateResponse(response);
}

export async function getRequestDetail(
  userId: string,
  requestId: string,
): Promise<RequestDetail> {
  const response = await apiFetch<unknown>(`/reviews/${requestId}`, {
    method: "GET",
    userId,
  });

  return normalizeDetailResponse(response);
}

export async function updateRequestStatus(
  userId: string,
  requestId: string,
  payload: UpdateRequestStatusPayload,
): Promise<UpdateRequestStatusResponse> {
  const response = await apiFetch<unknown>(`/reviews/${requestId}/status`, {
    method: "PATCH",
    userId,
    body: payload,
  });

  return normalizeUpdateResponse(response);
}
