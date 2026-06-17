import { Navigate, Outlet } from "react-router-dom";

import { useAuth } from "../../app/providers/AuthProvider";

type ProtectedRouteProps = {
  children?: JSX.Element;
};

export function ProtectedRoute({ children }: ProtectedRouteProps) {
  const { isAuthenticated, isLoading } = useAuth();

  if (isLoading) {
    return <div style={{ padding: "2rem" }}>Checking session...</div>;
  }

  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }

  return children ?? <Outlet />;
}
