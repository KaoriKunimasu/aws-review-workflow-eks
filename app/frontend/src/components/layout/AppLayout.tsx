import { NavLink, Outlet } from "react-router-dom";

import { useAuth } from "../../app/providers/AuthProvider";

function getDisplayName(claims: Record<string, unknown>): string {
  const email = claims.email;
  const cognitoUsername = claims["cognito:username"];
  const username = claims.username;
  const subject = claims.sub;

  if (typeof email === "string" && email.trim() !== "") {
    return email;
  }

  if (typeof cognitoUsername === "string" && cognitoUsername.trim() !== "") {
    return cognitoUsername;
  }

  if (typeof username === "string" && username.trim() !== "") {
    return username;
  }

  if (typeof subject === "string" && subject.trim() !== "") {
    return subject;
  }

  return "Signed-in user";
}

export function AppLayout() {
  const { claims, logout } = useAuth();
  const displayName = getDisplayName(claims);

  return (
    <div style={{ minHeight: "100vh", display: "grid", gridTemplateColumns: "240px 1fr" }}>
      <aside style={{ padding: "1.5rem", borderRight: "1px solid #ddd" }}>
        <h2 style={{ marginTop: 0 }}>Review Workflow</h2>
        <nav style={{ display: "grid", gap: "0.75rem" }}>
          <NavLink to="/dashboard">Dashboard</NavLink>
          <NavLink to="/requests">Requests</NavLink>
          <NavLink to="/requests/new">New Request</NavLink>
        </nav>
      </aside>

      <div>
        <header
          style={{
            padding: "1rem 1.5rem",
            borderBottom: "1px solid #ddd",
            display: "flex",
            justifyContent: "space-between",
            alignItems: "center",
            gap: "1rem",
          }}
        >
          <div>
            <strong>Signed in as:</strong> {displayName}
          </div>
          <button type="button" onClick={logout}>
            Sign out
          </button>
        </header>

        <main style={{ padding: "1.5rem" }}>
          <Outlet />
        </main>
      </div>
    </div>
  );
}
