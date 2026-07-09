import { useState, type FormEvent } from "react";
import { useNavigate } from "react-router-dom";

import { useAuth } from "../app/providers/AuthProvider";
import { ApiError } from "../lib/api/client";
import { createRequest } from "../lib/api/requests";

export function NewRequestPage() {
  const navigate = useNavigate();
  const { claims } = useAuth();

  const userId = typeof claims.sub === "string" ? claims.sub : "";

  const [title, setTitle] = useState("");
  const [requestType, setRequestType] = useState("term");
  const [sourceLanguage, setSourceLanguage] = useState("en");
  const [targetLanguage, setTargetLanguage] = useState("ja");
  const [sourceText, setSourceText] = useState("");
  const [targetText, setTargetText] = useState("");
  const [category, setCategory] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [errorMessage, setErrorMessage] = useState("");

async function handleSubmit(event: FormEvent<HTMLFormElement>) {
  event.preventDefault();

  if (!userId) {
    setErrorMessage("You must be signed in to submit a request.");
    return;
  }

  try {
    setSubmitting(true);
    setErrorMessage("");

    await createRequest(userId, {
      title: title.trim(),
      requestType,
      sourceLanguage: sourceLanguage.trim(),
      targetLanguage: targetLanguage.trim(),
      sourceText: sourceText.trim(),
      targetText: targetText.trim(),
      category: category.trim(),
    });

    navigate("/requests", { replace: true });
  } catch (error) {
    if (error instanceof ApiError) {
      setErrorMessage(error.message);
    } else if (error instanceof Error) {
      setErrorMessage(error.message);
    } else {
      setErrorMessage("Failed to create the request.");
    }
  } finally {
    setSubmitting(false);
  }
}


  return (
    <section className="page">
      <header className="page-header">
        <div>
          <h1>New Request</h1>
          <p>Create a new review request.</p>
        </div>
      </header>

      <section className="card form-card">
        {errorMessage ? (
          <div style={{ marginBottom: "1rem", color: "#b00020" }}>{errorMessage}</div>
        ) : null}

        <form className="form-grid" onSubmit={(event) => void handleSubmit(event)}>
          <label className="form-field">
            <span>Title</span>
            <input
              className="input"
              type="text"
              placeholder="Enter a title"
              value={title}
              onChange={(event) => setTitle(event.target.value)}
              required
            />
          </label>

          <label className="form-field">
            <span>Request Type</span>
            <select
              className="input"
              value={requestType}
              onChange={(event) => setRequestType(event.target.value)}
            >
              <option value="term">Term</option>
              <option value="document">Document</option>
              <option value="change">Change</option>
            </select>
          </label>

          <label className="form-field">
            <span>Source Language</span>
            <input
              className="input"
              type="text"
              value={sourceLanguage}
              onChange={(event) => setSourceLanguage(event.target.value)}
              required
            />
          </label>

          <label className="form-field">
            <span>Target Language</span>
            <input
              className="input"
              type="text"
              value={targetLanguage}
              onChange={(event) => setTargetLanguage(event.target.value)}
              required
            />
          </label>

          <label className="form-field form-field--full">
            <span>Source Text</span>
            <textarea
              className="input input--textarea"
              placeholder="Enter source text"
              rows={4}
              value={sourceText}
              onChange={(event) => setSourceText(event.target.value)}
              required
            />
          </label>

          <label className="form-field form-field--full">
            <span>Target Text</span>
            <textarea
              className="input input--textarea"
              placeholder="Enter target text"
              rows={4}
              value={targetText}
              onChange={(event) => setTargetText(event.target.value)}
            />
          </label>

          <label className="form-field">
            <span>Category</span>
            <input
              className="input"
              type="text"
              placeholder="security"
              value={category}
              onChange={(event) => setCategory(event.target.value)}
            />
          </label>

          <div className="form-actions form-field--full">
            <button type="button" className="button button--secondary" disabled>
              Save Draft
            </button>
            <button
              type="submit"
              className="button button--primary"
              disabled={submitting}
            >
              {submitting ? "Submitting..." : "Submit"}
            </button>
          </div>
        </form>
      </section>
    </section>
  );
}
