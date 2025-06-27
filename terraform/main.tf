terraform {
  backend "s3" {
    bucket               = "elemnta-rnd-terraform-state"
    key                  = "terraform.tfstate"
    dynamodb_table       = "elemnta-rnd-terraform-state-lock"
    region               = "ap-southeast-1"
    workspace_key_prefix = "elemnta-lgtm"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.87.0"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Terraform   = "true"
      Environment = var.environment
      Service     = "elemnta-lgtm"
      Author      = "Elemnta"
    }
  }

}


module "ecs" {
  source         = "./package"
  service_prefix = "${var.service_name}-${var.environment}"
}
