terraform {
  required_version = ">= 1.8.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.5"
    }

    # Required by the EKS module (v20.x) for access entries / cluster auth.
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }

    time = {
      source  = "hashicorp/time"
      version = "~> 0.12"
    }
  }
}
