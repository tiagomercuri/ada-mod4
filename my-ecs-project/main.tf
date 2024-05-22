terraform {
  backend "s3" {
    bucket         = "my-ecs-project-4789-tf-state"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "my-ecs-project-4789-tf-lock"
    encrypt        = true
  }
}

module "network" {
  source = "./network"
  project_name = var.project_name
  vpc_cidr_block = "10.0.0.0/16"
  subnet_cidr_blocks = ["10.0.1.0/24", "10.0.2.0/24"]
  availability_zones = ["us-east-1a", "us-east-1b"]
}

module "ecs_cluster" {
  source                 = "./ecs_module"
  region                 = var.region
  project_name           = var.project_name
  task_execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  ecs_cluster_name       = "${var.project_name}-cluster"
  vpc_id                 = module.network.vpc_id
  subnet_ids             = [for id in module.network.subnet_ids : id]
}

module "ecs_services" {
  source                 = "./ecs_module"
  region                 = var.region
  project_name           = var.project_name
  ecs_cluster_name       = "${var.project_name}-cluster"
  task_execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  vpc_id                 = module.network.vpc_id
  subnet_ids             = [for id in module.network.subnet_ids : id]
}

output "alb_dns_name" {
  value       = module.ecs_services.alb_dns_name
  description = "The DNS name for the application load balancer"
}
