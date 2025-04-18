resource "aws_vpc" "default" {
  count = local.use_default_vpc ? 1 : 0
  
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  
  tags = {
    Name        = "${var.environment_name}-default-vpc"
    Environment = var.environment_name
  }
}

resource "aws_internet_gateway" "default" {
  count = local.use_default_vpc ? 1 : 0
  
  vpc_id = aws_vpc.default[0].id
  
  tags = {
    Name        = "${var.environment_name}-igw"
    Environment = var.environment_name
  }
}

resource "aws_route_table" "default" {
  count = local.use_default_vpc ? 1 : 0
  
  vpc_id = aws_vpc.default[0].id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.default[0].id
  }
  
  tags = {
    Name        = "${var.environment_name}-rtb"
    Environment = var.environment_name
  }
}

resource "aws_subnet" "subnet_a" {
  count = local.use_default_vpc ? 1 : 0
  
  vpc_id                  = aws_vpc.default[0].id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  
  tags = {
    Name        = "${var.environment_name}-subnet-a"
    Environment = var.environment_name
  }
}

resource "aws_subnet" "subnet_b" {
  count = local.use_default_vpc ? 1 : 0
  
  vpc_id                  = aws_vpc.default[0].id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true
  
  tags = {
    Name        = "${var.environment_name}-subnet-b"
    Environment = var.environment_name
  }
}

resource "aws_route_table_association" "subnet_a" {
  count = local.use_default_vpc ? 1 : 0
  
  subnet_id      = aws_subnet.subnet_a[0].id
  route_table_id = aws_route_table.default[0].id
}

resource "aws_route_table_association" "subnet_b" {
  count = local.use_default_vpc ? 1 : 0
  
  subnet_id      = aws_subnet.subnet_b[0].id
  route_table_id = aws_route_table.default[0].id
}

resource "aws_security_group" "alb" {
  name        = "${local.name_prefix}-alb-sg"
  description = "Security group for the Application Load Balancer"
  vpc_id      = local.use_default_vpc ? aws_vpc.default[0].id : var.vpc_id
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name        = "${local.name_prefix}-alb-sg"
    Project     = "fast-agent-fz-docker"
    Environment = var.environment_name
  }
}

resource "aws_security_group" "fargate" {
  name        = "${local.name_prefix}-fargate-sg"
  description = "Security group for the Fargate service tasks"
  vpc_id      = local.use_default_vpc ? aws_vpc.default[0].id : var.vpc_id
  
  ingress {
    from_port       = local.container_port
    to_port         = local.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name        = "${local.name_prefix}-fargate-sg"
    Project     = "fast-agent-fz-docker"
    Environment = var.environment_name
  }
}

data "aws_availability_zones" "available" {} 