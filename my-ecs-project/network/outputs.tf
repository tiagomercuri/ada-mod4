output "vpc_id" {
  value = aws_vpc.ecs_vpc.id
}

output "subnet_ids" {
  description = "IDs of the subnets"
  value       = aws_subnet.ecs_subnet[*].id
}

