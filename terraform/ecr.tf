/* Comment out ECR resource since it already exists
resource "aws_ecrpublic_repository" "repo" {
  provider = aws.us_east_1 # ECR Public is only available in us-east-1

  repository_name = local.repo_name

  catalog_data {
    about_text        = "Fast Agent FZ container images for the ${var.environment_name} environment"
    usage_text        = "Docker pull instructions"
    operating_systems = ["Linux"]
    architectures     = ["x86_64"]
  }

  # Prevent recreation of ECR repository if it already exists
  lifecycle {
    ignore_changes = [
      repository_name
    ]
  }

  tags = {
    Name        = "${local.name_prefix}-public-repo"
    Project     = "fast-agent-fz-docker"
    Environment = var.environment_name
  }
}
*/
