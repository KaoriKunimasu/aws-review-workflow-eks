# Lambda Packaging Workflow

## Purpose

This document describes how Lambda function source files are prepared for zip-based deployment.

## Current Source Layout

```text
app/functions/
├─ shared/
├─ list_requests/
└─ create_request/
```

## Packaging Goal

Each Lambda function must have a deployable directory that can be zipped independently.

The deployable package must place the handler file at the root of the archive. Shared application code that the handler imports must also be included in the same package.

## Build Output Layout

```text
app/functions/.dist/
├─ list_requests/
│  ├─ handler.py
│  └─ shared/
└─ create_request/
   ├─ handler.py
   └─ shared/
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

## Terraform Integration Plan

A later infrastructure PR will package each directory under `.dist` as a zip archive and pass it to the Lambda module.

The expected Lambda handler value will be:

```
handler.lambda_handler
```

## Current Limitations

- Dependency installation is not implemented yet
- Zip archive creation is not implemented yet
- Terraform wiring is not implemented yet
- API Gateway integration is not implemented yet
