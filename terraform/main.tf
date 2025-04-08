provider "aws" {
  region = var.region
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

variable "environment_name" {
  description = "Environment name for the stack"
  type        = string
  default     = "dev"
}

variable "image_tag" {
  description = "Docker image tag to use"
  type        = string
  default     = "latest"
}

variable "ecr_public_alias" {
  description = "Your ECR Public registry alias"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID to deploy the resources into. Leave empty to use default VPC."
  type        = string
  default     = ""
}

variable "subnet_ids" {
  description = "List of Subnet IDs. Leave empty to use default subnets."
  type        = list(string)
  default     = []
}

variable "initial_desired_count" {
  description = "Initial number of tasks to run"
  type        = number
  default     = 0
}

locals {
  name_prefix     = "${var.environment_name}-fast-agent-fz"
  use_default_vpc = var.vpc_id == ""
  container_name  = "${local.name_prefix}-container"
  container_port  = 7681
  repo_name       = "${var.environment_name}-fast-agent-fz"
  repo_uri        = "public.ecr.aws/${var.ecr_public_alias}/${local.repo_name}"
  image_uri       = "${local.repo_uri}:${var.image_tag}"
} 