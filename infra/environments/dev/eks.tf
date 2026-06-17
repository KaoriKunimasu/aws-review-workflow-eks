# Dedicated VPC for the EKS cluster, isolated from the serverless resources.
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.13"

  name = "${local.name_prefix}-eks"
  cidr = "10.0.0.0/16"

  azs             = ["${var.aws_region}a", "${var.aws_region}b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true # Cost: one NAT gateway is enough for dev.

  # Tags so the AWS Load Balancer Controller can discover subnets later.
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  tags = local.common_tags
}

module "eks" {
  source = "terraform-aws-modules/eks/aws"
  # Pin to a v20.x release compatible with AWS provider 5.x.
  # Verify the exact patch on the Terraform Registry before init.
  version = "20.24.0"

  cluster_name    = local.name_prefix
  cluster_version = "1.31"

  cluster_endpoint_public_access = true

  # Grant the Terraform-running principal admin via an access entry
  # (access entries are recommended over the deprecated aws-auth ConfigMap).
  enable_cluster_creator_admin_permissions = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    default = {
      instance_types = ["t3.small"]
      min_size       = 2
      max_size       = 3
      desired_size   = 2
    }
  }

  tags = local.common_tags
}
