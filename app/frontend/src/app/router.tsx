import { createBrowserRouter, Navigate } from "react-router-dom";

import { ProtectedRoute } from "../components/auth/ProtectedRoute";
import { AppLayout } from "../components/layout/AppLayout";
import { AuthCallbackPage } from "../pages/AuthCallbackPage";
import { DashboardPage } from "../pages/DashboardPage";
import { LoginPage } from "../pages/LoginPage";
import { NewRequestPage } from "../pages/NewRequestPage";
import { RequestDetailPage } from "../pages/RequestDetailPage";
import { RequestsPage } from "../pages/RequestsPage";

export const router = createBrowserRouter([
  {
    path: "/login",
    element: <LoginPage />,
  },
  {
    path: "/auth/callback",
    element: <AuthCallbackPage />,
  },
  {
    path: "/",
    element: <ProtectedRoute />,
    children: [
      {
        element: <AppLayout />,
        children: [
          {
            index: true,
            element: <Navigate to="/dashboard" replace />,
          },
          {
            path: "dashboard",
            element: <DashboardPage />,
          },
          {
            path: "requests",
            element: <RequestsPage />,
          },
          {
            path: "requests/new",
            element: <NewRequestPage />,
          },
          {
            path: "requests/:requestId",
            element: <RequestDetailPage />,
          },
        ],
      },
    ],
  },
  {
    path: "*",
    element: <Navigate to="/dashboard" replace />,
  },
]);
