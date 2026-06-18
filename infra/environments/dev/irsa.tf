# IAM policy granting least-privilege DynamoDB access to the review API,
# mirroring the per-function permissions of the original Lambda handlers.
data "aws_iam_policy_document" "review_api_dynamodb" {
  statement {
    sid    = "WorkflowTableAccess"
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
    ]
    resources = [
      module.dynamodb.table_arn,
      "${module.dynamodb.table_arn}/index/*",
    ]
  }
}

# IRSA role: trusted by the cluster OIDC provider, assumable only by the
# review-api ServiceAccount in the default namespace.
module "review_api_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.44"

  role_name = "${local.name_prefix}-review-api-irsa"

  role_policy_arns = {
    dynamodb = aws_iam_policy.review_api_dynamodb.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["default:review-api"]
    }
  }

  tags = local.common_tags
}

resource "aws_iam_policy" "review_api_dynamodb" {
  name   = "${local.name_prefix}-review-api-dynamodb"
  policy = data.aws_iam_policy_document.review_api_dynamodb.json
  tags   = local.common_tags
}
