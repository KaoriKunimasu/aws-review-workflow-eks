# ADR-0001: Project Scope

## Status
Accepted

## Context
A generic CRUD application does not provide enough surface area to demonstrate
infrastructure design, security patterns, or operational practices in a meaningful way.

A domain with structured lifecycle states, user roles, and audit requirements
is better suited for showcasing serverless architecture and workflow automation.

## Decision
The project will be a cloud-first internal workflow platform on AWS for technical
terminology and document review.

The project will prioritize:
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
- Serverless and IaC patterns map naturally to the domain requirements

### Negative
- Domain is narrow enough that some AWS services have limited justification at MVP scale
- Translation-specific features are deferred or excluded to keep scope manageable
