# Lambda Packaging Workflow

## Purpose

This document describes how Lambda function source files are prepared for zip-based deployment.

## Current Source Layout

```text
app/functions/
├─ shared/
├─ list_requests/
├─ create_request/
├─ get_request_detail/
├─ update_request_status/
└─ pre_token_generation/
```

The first four are the original handlers behind the HTTP API. `pre_token_generation` is a Cognito trigger rather than an API route; it puts group membership on the access token, and `docs/adr/0005-reviewer-group-authorization.md` covers why.

## Packaging Goal

Each Lambda function must have a deployable directory that can be zipped independently.

The deployable package must place the handler file at the root of the archive. Shared application code that the handler imports must also be included in the same package.

## Build Output Layout

```text
app/functions/.dist/
├─ list_requests/
│  ├─ handler.py
│  └─ shared/
├─ create_request/
│  ├─ handler.py
│  └─ shared/
├─ get_request_detail/
├─ update_request_status/
└─ pre_token_generation/
```

## Build Command

```bash
python scripts/package_lambda_functions.py
```

## What the Script Does

- Recreates `app/functions/.dist`
- Copies each function `handler.py` into its package root
- Copies `requirements.txt` when present
- Copies the shared helper package into each function package

The function list is hardcoded at the top of the script, so a new function has to be added there before it gets packaged.

## Terraform Integration

Each function has an `archive_file` data source in `infra/environments/dev/main.tf` that zips its `.dist` directory and hands the result to the `lambda-function` module. The handler value is:

```
handler.lambda_handler
```

The four API functions are wired to HTTP API routes with a Cognito JWT authorizer in front. The pre-token-generation function is attached to the user pool instead, in the `cognito` module.

Run the packaging script before `terraform plan` or `apply`. Everything under `.dist` is gitignored, so on a fresh checkout there's nothing for `archive_file` to read and the plan fails.

## Current Limitations

- Dependency installation is not implemented. Every `requirements.txt` here is empty right now, since the handlers only use `boto3` and the Lambda runtime already ships it. A function with real dependencies would need this filled in first.
- `shared/` gets copied into every package, including `pre_token_generation`, which never imports it. It's dead weight in the archive, nothing more.
