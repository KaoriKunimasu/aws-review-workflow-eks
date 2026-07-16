import { useCallback, useEffect, useMemo, useState } from "react";
import { Link } from "react-router-dom";
import { useAuth } from "../app/providers/AuthProvider";
import { ApiError } from "../lib/api/client";
import { listRequests } from "../lib/api/requests";
import type { WorkflowRequest } from "../types/request";

function formatStatusLabel(status?: string): string {
  if (!status) {
    return "open";
  }

  return status.replaceAll("_", " ");
}

function normalizeStatus(status?: string): string {
  return (status ?? "open").toLowerCase();
}

export function RequestsPage() {
  const { claims } = useAuth();
  const userId = typeof claims.sub === "string" ? claims.sub : "";

  const [requests, setRequests] = useState<WorkflowRequest[]>([]);
  const [loading, setLoading] = useState(true);
  const [errorMessage, setErrorMessage] = useState("");
  const [searchTerm, setSearchTerm] = useState("");
  const [statusFilter, setStatusFilter] = useState("all");

  const hasUserId = useMemo(() => userId.length > 0, [userId]);

  const filteredRequests = useMemo(() => {
    const normalizedSearch = searchTerm.trim().toLowerCase();

    return requests.filter((request) => {
      const normalizedRequestStatus = normalizeStatus(request.status);

      const matchesStatus =
        statusFilter === "all" ? true : normalizedRequestStatus === statusFilter;

      const searchableText = [
        request.requestId,
        request.title,
        request.sourceLanguage,
        request.targetLanguage,
        normalizedRequestStatus,
      ]
        .filter(Boolean)
        .join(" ")
        .toLowerCase();

      const matchesSearch =
        normalizedSearch.length === 0
          ? true
          : searchableText.includes(normalizedSearch);

      return matchesStatus && matchesSearch;
    });
  }, [requests, searchTerm, statusFilter]);

  const loadRequests = useCallback(async () => {
    if (!hasUserId) {
      setErrorMessage("You must be signed in to view requests.");
      setLoading(false);
      return;
    }

    try {
      setLoading(true);
      setErrorMessage("");

      const response = await listRequests();
      setRequests(response.items);
    } catch (error) {
      if (error instanceof ApiError) {
        setErrorMessage(error.message);
      } else if (error instanceof Error) {
        setErrorMessage(error.message);
      } else {
        setErrorMessage("Failed to load requests.");
      }
    } finally {
      setLoading(false);
    }
  }, [hasUserId]);

  useEffect(() => {
    void loadRequests();
  }, [loadRequests]);

  return (
    <section className="page">
      <header className="page-header">
        <div>
          <h1>Requests</h1>
          <p>Review and track submitted workflow items.</p>
        </div>
      </header>

      <section className="card">
        <div className="table-toolbar">
          <input
            className="input"
            type="text"
            placeholder="Search by request ID, title, language, or status"
            value={searchTerm}
            onChange={(event) => setSearchTerm(event.target.value)}
          />

          <select
            className="input"
            value={statusFilter}
            onChange={(event) => setStatusFilter(event.target.value)}
          >
            <option value="all">All statuses</option>
            <option value="open">Open</option>
            <option value="in_review">In Review</option>
            <option value="approved">Approved</option>
            <option value="rejected">Rejected</option>
          </select>

          <button type="button" onClick={() => void loadRequests()} disabled={loading}>
            {loading ? "Loading..." : "Refresh"}
          </button>
        </div>

        <p style={{ margin: "0 0 1rem", color: "#555" }}>
          Showing {filteredRequests.length} of {requests.length} requests
        </p>

        {errorMessage ? (
          <div className="card" style={{ marginBottom: "1rem", color: "#b00020" }}>
            {errorMessage}
          </div>
        ) : null}

        {!loading && !errorMessage && requests.length === 0 ? (
          <div className="card">No requests found yet.</div>
        ) : null}

        {!loading &&
        !errorMessage &&
        requests.length > 0 &&
        filteredRequests.length === 0 ? (
          <div className="card">No matching requests found.</div>
        ) : null}

        <div className="table-wrapper">
          <table className="table">
            <thead>
              <tr>
                <th>Request ID</th>
                <th>Title</th>
                <th>Source</th>
                <th>Target</th>
                <th>Status</th>
              </tr>
            </thead>
            <tbody>
              {filteredRequests.map((request) => (
                <tr key={request.requestId}>
                  <td>{request.requestId}</td>
                  <td>
                    <Link to={`/requests/${request.requestId}`}>{request.title}</Link>
                  </td>
                  <td>{request.sourceLanguage}</td>
                  <td>{request.targetLanguage}</td>
                  <td>
                    <span
                      className={`status-badge status-badge--${normalizeStatus(
                        request.status,
                      )}`}
                    >
                      {formatStatusLabel(request.status)}
                    </span>
                  </td>
                </tr>
              ))}

              {loading ? (
                <tr>
                  <td colSpan={5}>Loading requests...</td>
                </tr>
              ) : null}
            </tbody>
          </table>
        </div>
      </section>
    </section>
  );
}
