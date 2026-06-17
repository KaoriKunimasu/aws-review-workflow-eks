# Local Development

## Prerequisites

- AWS CLI configured for the target account
- Terraform `>= 1.8.0`
- Python `>= 3.12`
- Node.js `>= 22.12.0`
- Git

## Local-Only Files

Do not commit the following files:

- `app/frontend/.env.local`
- `infra/environments/dev/terraform.tfvars`

Use the example files as references:

- `app/frontend/.env.example`
- `infra/environments/dev/terraform.tfvars.example`

## Frontend Environment

Create `app/frontend/.env.local` and configure the following values:

- `VITE_API_BASE_URL` — API Gateway invoke URL
- `VITE_COGNITO_BASE_URL` — Cognito hosted UI base URL
- `VITE_COGNITO_CLIENT_ID` — Cognito app client ID
- `VITE_COGNITO_REDIRECT_URI` — `http://localhost:5173/auth/callback`
- `VITE_COGNITO_LOGOUT_URI` — `http://localhost:5173/login`

## Terraform Environment

Create `infra/environments/dev/terraform.tfvars` from the example file and fill in the required values.

- `terraform.tfvars.example` is not loaded automatically
- Use a real `terraform.tfvars` file when running `terraform plan` or `terraform apply`

## Lambda Packaging

Before running `terraform apply`, package the Lambda functions:

```powershell
python .\scripts\package_lambda_functions.py
```

Packaged output is generated under `app/functions/.dist/`. Do not commit `.dist`.

If you add a new Lambda function, confirm that the packaging script includes it or detects it automatically.

## Deploy the Dev Environment

```powershell
cd .\infra\environments\dev
terraform init
terraform plan
terraform apply
```

## Run the Frontend

```powershell
cd .\app\frontend
npm install
npm run dev
```

## Destroy Resources to Control Cost

If you only need temporary verification, destroy the dev resources after testing:

```powershell
cd .\infra\environments\dev
terraform destroy
```

## Troubleshooting

**Cognito redirect mismatch**

If Cognito returns `redirect_mismatch`, confirm that:

- The frontend redirect URI is `http://localhost:5173/auth/callback`
- The Cognito callback URL in the app client matches exactly
- Terraform variables are not still pointing to `/login`

**API base URL**

`VITE_API_BASE_URL` must point to the API Gateway invoke URL, not the Cognito domain.

**Lambda reserved environment variables**

Do not set `AWS_REGION` in Lambda environment variables. AWS reserves it.

**DynamoDB key names**

The workflow table uses `PK` and `SK`. Do not use lowercase `pk` or `sk` in Lambda handlers.

**New API methods and CORS**

If a new HTTP method such as `PATCH` is added, make sure API Gateway CORS allows that method before testing from the browser.

**Terraform module updates**

If you add a new module block and Terraform cannot find it, run:

```powershell
terraform init
```
