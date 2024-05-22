variable "region" {
  description = "AWS region to deploy resources"
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project to create resources for"
  default     = "my-ecs-project-4789"
}

variable "aws_access_key" {
  description = "Access Key ID da AWS"
  type        = string
  sensitive   = true
  default     = ""
}

variable "aws_secret_key" {
  description = "Secret Access Key da AWS"
  type        = string
  sensitive   = true
  default     = ""
}
