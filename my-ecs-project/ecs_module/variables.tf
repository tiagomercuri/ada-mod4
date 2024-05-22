variable "project_name" {
  description = "Name of the project to create resources for"
  type        = string
}

variable "region" {
  description = "AWS region to deploy resources"
  type        = string
}

variable "task_execution_role_arn" {
  description = "The ARN of the task execution role"
  type        = string
}

variable "ecs_cluster_name" {
  description = "The name of the ECS cluster"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs"
  type        = list(string)
}

variable "unique_suffix" {
  description = "A unique suffix to avoid naming conflicts"
  type        = string
  default     = "001"  # você pode mudar isso para qualquer valor único
}
