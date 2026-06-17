# DynamoDB Module

This module manages the DynamoDB table used for workflow data.

## Resources

- Amazon DynamoDB table
- Global secondary index for alternate query patterns

## Design Choices

- Single-table style primary key design
- On-demand billing for low operational overhead
- Point-in-time recovery enabled
- Server-side encryption enabled
- Status-based query support through a global secondary index

## Table Keys

### Primary Keys

- Partition key: `PK`
- Sort key: `SK`

### Global Secondary Index

- Index name: `GSI1`
- Partition key: `GSI1PK`
- Sort key: `GSI1SK`

## Intended Access Patterns

- Get a single request by primary key
- List requests by status
- Support future query patterns without table scans

## Usage

```hcl
module "dynamodb" {
  source = "../../modules/dynamodb"

  name_prefix = "review-workflow-dev"

  tags = {
    Application = "review-workflow"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
```

## Notes

- The module is intentionally scoped to `PAY_PER_REQUEST` billing mode.
- Only attributes used in the table key schema or index key schema are declared.
- GSI queries are eventually consistent.
