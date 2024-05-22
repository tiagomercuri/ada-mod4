resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_lb" "ecs_alb" {
  name               = "${var.project_name}-alb-${random_id.suffix.hex}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ecs_sg.id]
  subnets            = aws_subnet.ecs_subnet[*].id

  tags = {
    Name = "${var.project_name}-alb-${random_id.suffix.hex}"
  }
}

resource "aws_lb_target_group" "ecs_tg" {
  name        = "${var.project_name}-tg-${random_id.suffix.hex}"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.ecs_vpc.id
  target_type = "ip"

  health_check {
    enabled             = true
    interval            = 30
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
    healthy_threshold   = 2
  }

  tags = {
    Name = "${var.project_name}-tg-${random_id.suffix.hex}"
  }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.ecs_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_tg.arn
  }
}

resource "aws_ecs_task_definition" "transaction_producer" {
  family                   = "transaction-producer"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = var.task_execution_role_arn
  task_role_arn            = var.task_execution_role_arn

  container_definitions = jsonencode([
    {
      name        = "transaction-producer"
      image       = "tiagomercuri/transaction-producer:latest"
      essential   = true
      portMappings = [
        {
          containerPort = 5672
          hostPort      = 5672
        }
      ]
      environment = [
        { name = "RABBITMQ_HOST", value = "rabbitmq" },
        { name = "RABBITMQ_PORT", value = "5672" }
      ]
    }
  ])
}

resource "aws_ecs_task_definition" "fraud_validator_consumer" {
  family                   = "fraud-validator-consumer"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = var.task_execution_role_arn
  task_role_arn            = var.task_execution_role_arn

  container_definitions = jsonencode([
    {
      name        = "fraud-validator-consumer"
      image       = "tiagomercuri/fraud-validator-consumer:latest"
      essential   = true
      portMappings = [
        {
          containerPort = 5672
          hostPort      = 5672
        }
      ]
      environment = [
        { name = "MINIO_HOST", value = "minio" },
        { name = "MINIO_ACCESS_KEY", value = "ROOTNAME" },
        { name = "MINIO_SECRET_KEY", value = "CHANGEME123" },
        { name = "MINIO_BUCKET", value = "relatorio" },
        { name = "REDIS_HOST", value = "redis" },
        { name = "REDIS_PORT", value = "6379" },
        { name = "RABBITMQ_HOST", value = "rabbitmq" },
        { name = "RABBITMQ_PORT", value = "5672" }
      ]
    }
  ])
}

resource "aws_ecs_task_definition" "minio" {
  family                   = "minio"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = var.task_execution_role_arn
  task_role_arn            = var.task_execution_role_arn

  container_definitions = jsonencode([
    {
      name        = "minio"
      image       = "quay.io/minio/minio"
      essential   = true
      portMappings = [
        {
          containerPort = 9000
          hostPort      = 9000
        },
        {
          containerPort = 3000
          hostPort      = 3000
        }
      ]
      environment = [
        { name = "MINIO_ROOT_USER", value = "ROOTNAME" },
        { name = "MINIO_ROOT_PASSWORD", value = "CHANGEME123" }
      ]
      command = ["server", "/data", "--console-address", ":3000"]
    }
  ])
}

resource "aws_ecs_task_definition" "rabbitmq" {
  family                   = "rabbitmq"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = var.task_execution_role_arn
  task_role_arn            = var.task_execution_role_arn

  container_definitions = jsonencode([
    {
      name        = "rabbitmq"
      image       = "rabbitmq:3-management"
      essential   = true
      portMappings = [
        {
          containerPort = 5672
          hostPort      = 5672
        },
        {
          containerPort = 15672
          hostPort      = 15672
        }
      ]
    }
  ])
}

resource "aws_ecs_task_definition" "redis" {
  family                   = "redis"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = var.task_execution_role_arn
  task_role_arn            = var.task_execution_role_arn

  container_definitions = jsonencode([
    {
      name        = "redis"
      image       = "redis:6.2"
      essential   = true
      portMappings = [
        {
          containerPort = 6379
          hostPort      = 6379
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "transaction_producer" {
  name            = "${var.project_name}-transaction-producer-service-${random_id.suffix.hex}"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.transaction_producer.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_tg.arn
    container_name   = "transaction-producer"
    container_port   = 5672
  }

  network_configuration {
    subnets          = [for subnet in aws_subnet.ecs_subnet : subnet.id]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  depends_on = [
    aws_lb_listener.front_end
  ]
}

resource "aws_ecs_service" "fraud_validator_consumer" {
  name            = "${var.project_name}-fraud-validator-consumer-service-${random_id.suffix.hex}"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.fraud_validator_consumer.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_tg.arn
    container_name   = "fraud-validator-consumer"
    container_port   = 5672
  }

  network_configuration {
    subnets          = [for subnet in aws_subnet.ecs_subnet : subnet.id]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  depends_on = [
    aws_lb_listener.front_end
  ]
}

resource "aws_ecs_service" "minio" {
  name            = "${var.project_name}-minio-service-${random_id.suffix.hex}"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.minio.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_tg.arn
    container_name   = "minio"
    container_port   = 9000
  }

  network_configuration {
    subnets          = [for subnet in aws_subnet.ecs_subnet : subnet.id]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  depends_on = [
    aws_lb_listener.front_end
  ]
}

resource "aws_ecs_service" "rabbitmq" {
  name            = "${var.project_name}-rabbitmq-service-${random_id.suffix.hex}"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.rabbitmq.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_tg.arn
    container_name   = "rabbitmq"
    container_port   = 5672
  }

  network_configuration {
    subnets          = [for subnet in aws_subnet.ecs_subnet : subnet.id]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  depends_on = [
    aws_lb_listener.front_end
  ]
}

resource "aws_ecs_service" "redis" {
  name            = "${var.project_name}-redis-service-${random_id.suffix.hex}"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.redis.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_tg.arn
    container_name   = "redis"
    container_port   = 6379
  }

  network_configuration {
    subnets          = [for subnet in aws_subnet.ecs_subnet : subnet.id]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  depends_on = [
    aws_lb_listener.front_end
  ]
}
