# terraform {
#   required_providers {
#     aws = {
#         source = "hashicorp/aws"
#     }
#   }
# }

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0" # Requires AWS provider v5+ for all features
    }
    sdm = {
      source  = "strongdm/sdm"
      version = ">=14.20.0" # Requires StrongDM provider v14.13.0+ for all features
    }
    external = {
      source = "hashicorp/external" # Used for external data sources and commands
    }
  }

  required_version = ">= 1.1.0" # Requires Terraform 1.1.0+
}

provider "aws" {
    region = var.aws_region
    default_tags {
        tags = {
            Project = "sdm-hwrk"
            Environment = "testing"
        }
    } 
}
