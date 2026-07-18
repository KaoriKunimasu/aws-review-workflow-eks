# ADR-0001: Project Scope

## Status
Accepted

## Context
A plain CRUD app has too little going on to justify real infrastructure, auth,
and operational tooling. The domain needs enough structure to warrant those
choices.

Technical terminology and document review fits. Requests move through defined
states (open, in review, approved, rejected), submitters and reviewers are
separate roles, and who changed a request's status needs to be traceable.

## Decision
The project will be a cloud-first internal workflow platform on AWS for technical
terminology and document review.

The project will prioritise:
- Terraform-based infrastructure
- AWS serverless architecture
- Secure authentication and authorization
- Operational visibility and monitoring
- Documentation quality and explainability

## MVP Scope
- User authentication
- Request creation
- Request listing
- Request detail view
- Request status update
- Dashboard summary
- Protected API
- Basic CloudWatch monitoring
- GitHub Actions validation workflow

## Non-Goals
- AI-assisted translation
- Full-text search engine
- Multi-region deployment
- Container orchestration
- Complex RBAC
- Enterprise-grade admin console

## Consequences
### Positive
- Domain complexity justifies the use of structured workflow states and role-based access
- Serverless and IaC patterns fit the domain without forcing

### Negative
- Domain is narrow enough that some AWS services have limited justification at MVP scale
- Translation-specific features are deferred or excluded to keep scope manageable
