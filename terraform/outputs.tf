output "ecr_public_repository_name" {
  description = "Name of the ECR Public Repository"
  value       = aws_ecrpublic_repository.repo.repository_name
}

output "ecr_public_registry_alias" {
  description = "The ECR Public registry alias"
  value       = var.ecr_public_alias
}

output "ecr_public_repository_uri" {
  description = "URI of the ECR Public Repository"
  value       = local.repo_uri
}

output "docker_build_command" {
  description = "Command to build Docker image locally"
  value       = "docker build -t ${local.image_uri} ."
}

output "docker_login_command" {
  description = "Command to authenticate with ECR Public"
  value       = "aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws"
}

output "docker_push_command" {
  description = "Command to push Docker image to ECR Public"
  value       = "docker push ${local.image_uri}"
}

output "load_balancer_dns_name" {
  description = "The DNS name (public URL) of the Application Load Balancer"
  value       = aws_lb.alb.dns_name
}

output "ecs_service_name" {
  description = "Name of the ECS Service"
  value       = aws_ecs_service.service.name
}

output "ecs_cluster_name" {
  description = "Name of the ECS Cluster"
  value       = aws_ecs_cluster.cluster.name
} 