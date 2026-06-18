# ECR repository for the containerized review API image.
resource "aws_ecr_repository" "review_api" {
  name = "${local.name_prefix}-review-api"

  # MUTABLE so CI can push a moving tag (e.g. latest) during dev.
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = local.common_tags
}

resource "aws_ecr_lifecycle_policy" "review_api" {
  repository = aws_ecr_repository.review_api.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
