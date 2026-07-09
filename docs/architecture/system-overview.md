# System Overview

> **This document describes the original pre-migration (Lambda / API
> Gateway / Cognito authorizer) architecture and is kept for historical
> context.** This repository now runs the API as a FastAPI container on
> EKS; see the top-level [README](../../README.md) for the current
> architecture, and `docs/adr/0002-eks-migration-strategy.md` for what
> changed and why. Notably, the S3/CloudFront frontend hosting, the
> `get-profile` and `get-dashboard-summary` endpoints, SNS notifications,
> and the GitHub Actions/OIDC deployment pipeline described below were
> never built even in the original serverless version.

## Summary

This repository contains a serverless web application for managing review requests for technical terms and related content.

The system is built with managed AWS services and is deployed through infrastructure as code.

## Main Flow

1. The frontend is hosted in Amazon S3 and served through Amazon CloudFront.
2. Users sign in with Amazon Cognito.
3. The frontend sends authenticated requests to Amazon API Gateway.
4. API Gateway validates JWTs with a JWT authorizer.
5. API Gateway routes requests to AWS Lambda.
6. Lambda reads and writes data in Amazon DynamoDB.
7. Logs and metrics are sent to Amazon CloudWatch.
8. CloudWatch alarms can publish notifications to Amazon SNS.
9. Infrastructure is managed with Terraform.
10. GitHub Actions deploys changes by using OIDC-based AWS authentication.

## Core Components

### Frontend
- React
- Vite
- TypeScript
- static assets hosted in Amazon S3
- content delivered through Amazon CloudFront

### Authentication
- Amazon Cognito User Pool
- JWT-based authentication for protected routes

### API
- Amazon API Gateway HTTP API
- JWT authorizer for route protection

### Compute
AWS Lambda functions handle the main application logic, including:

- get-profile
- list-requests
- get-request
- create-request
- update-request-status
- get-dashboard-summary

### Data
- Amazon DynamoDB stores workflow records
- the table design should support request lookup and status-based access patterns

### Observability
- CloudWatch Logs for API and Lambda activity
- CloudWatch alarms for Lambda errors and API 5XX responses
- Amazon SNS for notifications

### Delivery
- Terraform for infrastructure provisioning
- GitHub Actions for validation and deployment
- OIDC for short-lived AWS credentials

## Initial Request Lifecycle

1. A signed-in user creates a request.
2. The request is stored with a workflow status.
3. A reviewer updates the request status and note.
4. The dashboard returns summary counts by status.

## Initial Scope

The first implementation focuses on:

- authentication
- request creation
- request listing
- request detail view
- request status update
- dashboard summary

## Out of Scope for the Initial Build

The initial build does not include:

- AI translation
- vector search
- OpenSearch
- ECS or Kubernetes
- multi-region deployment
- advanced RBAC
- document ingestion pipelines

## Related Files

- API contract: `docs/api/openapi.yaml`
- Diagram source: `diagrams/system-overview.mmd`
