// Declare local variables
locals {
  cidr_block = "10.32.0.0/16"
  public_cidr_offset = 2
  frontend_port = 3000
  backend_port = 8080
}
// Declare required Terraform providers
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

// Configure AWS provider with region
provider "aws" {
  region = "us-east-1"
}

// Get list of availability zones in the region
data "aws_availability_zones" "available_zones" {
  state = "available"
}

// Create a VPC with a specified CIDR block and name
resource "aws_vpc" "lightfeather" {
  cidr_block = local.cidr_block
  tags = {
    Name = "LightFeather"
  }
}

// Create public subnets with a specified CIDR block and availability zone in each zone
resource "aws_subnet" "public" {
  count                   = 2
  cidr_block              = cidrsubnet(local.cidr_block, 8, local.public_cidr_offset + count.index)
  availability_zone       = data.aws_availability_zones.available_zones.names[count.index]
  vpc_id                  = aws_vpc.lightfeather.id
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet"
  }
}

// Create private subnets with a specified CIDR block and availability zone in each zone
resource "aws_subnet" "private" {
  count             = 2
  cidr_block        = cidrsubnet(local.cidr_block, 8, count.index)
  availability_zone = data.aws_availability_zones.available_zones.names[count.index]
  vpc_id            = aws_vpc.lightfeather.id
  tags = {
    Name = "private-subnet"
  }
}

// Create an internet gateway and attach it to the VPC
resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.lightfeather.id
  tags = {
    Name = "internet-gateway"
  }
}

// Add a default route to the internet gateway in the main route table
resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.lightfeather.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gateway.id
}

// Create Elastic IPs for NAT gateways
resource "aws_eip" "gateway" {
  count      = 2
  vpc        = true
  depends_on = [aws_internet_gateway.gateway]
}

// Create NAT gateways in public subnets and associate them with Elastic IPs
resource "aws_nat_gateway" "gateway" {
  count         = 2
  subnet_id     = element(aws_subnet.public.*.id, count.index)
  allocation_id = element(aws_eip.gateway.*.id, count.index)
}

// Create private route tables and add a route to the NAT gateway
resource "aws_route_table" "private" {
  count  = 2
  vpc_id = aws_vpc.lightfeather.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.gateway.*.id, count.index)
  }
}

// Associates the private subnets with their corresponding route tables. 
resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
}

// Creates a security group for the load balancer.
resource "aws_security_group" "lb" {
  name  = "lightfeather-alb-security-group"
  vpc_id = aws_vpc.lightfeather.id

  ingress {
    protocol    = "tcp"
    from_port   = local.backend_port
    to_port     = local.backend_port
    cidr_blocks = ["0.0.0.0/0"]
  }

    ingress {
    protocol    = "tcp"
    from_port   = local.frontend_port
    to_port     = local.frontend_port
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

// Creates an Application Load Balancer and attaches it to the public subnets
resource "aws_lb" "lightfeather" {
  name            = "lightfeather-lb"
  subnets         = aws_subnet.public.*.id
  security_groups = [aws_security_group.lb.id]
}

// Creates target group for backend
resource "aws_lb_target_group" "backend" {
  name        = "lightfeather-target-group"
  port        = local.backend_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.lightfeather.id
  target_type = "ip"
}

// Creates target group for frontend
resource "aws_lb_target_group" "frontend" {
  name        = "frontend-target-group"
  port        = local.frontend_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.lightfeather.id
  target_type = "ip"
}

// Creates a listener for the load balancer on the backend port
resource "aws_lb_listener" "backend" {
  load_balancer_arn = aws_lb.lightfeather.arn
  port              = local.backend_port
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.backend.arn
    type             = "forward"
  }
}

// Greates a listener for the load balancer on the frontend port
resource "aws_lb_listener" "frontend" {
  load_balancer_arn = aws_lb.lightfeather.arn
  port              = local.frontend_port
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.frontend.arn
    type             = "forward"
  }
}

// Defines ECS task definition for backend service
resource "aws_ecs_task_definition" "backend" {
  family                   = "backend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 1024
  memory                   = 2048

  container_definitions = <<DEFINITION
[
  {
    "name": "backend",
    "image": "public.ecr.aws/c6p1p1z3/reviewclass-backend:14",
    "memoryReservation": 1024,
    "cpu":  512,
    "portMappings": [
      {
        "containerPort": 8080,
        "hostPort": 8080
      }
    ],
    "essential": true
  }
]
DEFINITION
}

// Defines ECS task definition for frontend service
resource "aws_ecs_task_definition" "frontend" {
  family                   = "frontend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 1024
  memory                   = 2048

  container_definitions = <<DEFINITION
[
  {
    "name": "frontend",
    "image": "public.ecr.aws/c6p1p1z3/reviewclass-frontend:14",
    "memoryReservation": 1024,
    "cpu":  512,
    "portMappings": [
      {
        "containerPort": 3000,
        "hostPort": 3000
      }
    ],
    "essential": true
  }
]
DEFINITION
}

// Creates security group for backend task
resource "aws_security_group" "backend" {
  name  = "lightfeather-backend-task-security-group"
  vpc_id = aws_vpc.lightfeather.id

    ingress {
    from_port       = local.backend_port
    to_port         = local.backend_port
    protocol        = "tcp"
    security_groups = [aws_security_group.lb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

// Creates security group for frontend task
resource "aws_security_group" "frontend" {
  name  = "lightfeather-frontend-task-security-group"
  vpc_id = aws_vpc.lightfeather.id

  ingress {
    from_port       = local.frontend_port
    to_port         = local.frontend_port
    protocol        = "tcp"
    security_groups = [aws_security_group.lb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

// Creates an ECS cluster for the services
resource "aws_ecs_cluster" "lightfeather-cluster" {
  name = "lightfeather-cluster"
}

// Creates ECS service for the backend task
resource "aws_ecs_service" "backend" {
  name            = "lightfeather-backend-service"
  cluster         = aws_ecs_cluster.lightfeather-cluster.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private.*.id
    security_groups  = [aws_security_group.backend.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.backend.arn
    container_name   = "backend"
    container_port   = local.backend_port
  }

  depends_on = [aws_lb_listener.backend]
}

// Creates ECS services for the frontend task
resource "aws_ecs_service" "frontend" {
  name            = "lightfeather-frontend-service"
  cluster         = aws_ecs_cluster.lightfeather-cluster.id
  task_definition = aws_ecs_task_definition.frontend.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private.*.id
    security_groups  = [aws_security_group.frontend.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.frontend.arn
    container_name   = "frontend"
    container_port   = local.frontend_port
  }

  depends_on = [aws_lb_listener.frontend]
}

// Outputs the applicattion load balancer DNS name
output "load_balancer_dns_name" {
  value = aws_lb.lightfeather.dns_name
}

