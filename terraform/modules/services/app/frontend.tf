resource "aws_ecr_repository" "frontend" {
  name = "${var.app_name}-${var.environment}-frontend"
}

resource "aws_cloudwatch_log_group" "frontend" {
  name = "${var.app_name}-${var.environment}-frontend"
}

resource "aws_lb_target_group" "frontend" {
  name        = "${var.app_name}-${var.environment}-frontend"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_default_vpc.default_vpc.id # Referencing the default VPC
  health_check {
    matcher = "200,301,302"
    path    = "/${var.service_configuration.frontend.url_prefix}"
  }
  depends_on = [aws_lb.application_load_balancer]
}

resource "aws_lb_listener_rule" "frontend" {
  listener_arn = aws_lb_listener.listener_https.arn
  # important! frontend is catchall, and must not override service-specific rules
  # Note: priority 1 -> first/highest priority vs. priority 99 -> low priority
  priority = 99
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
  condition {
    path_pattern {
      values = ["/${var.service_configuration.frontend.url_prefix}*"]
    }
  }
}

resource "aws_ecs_service" "frontend" {
  name            = "${var.app_name}-${var.environment}-frontend" # Naming our first service
  cluster         = aws_ecs_cluster.app.id                        # Referencing our created Cluster
  task_definition = aws_ecs_task_definition.frontend.arn          # Referencing the task our service will spin up
  launch_type     = "FARGATE"
  desired_count   = 2 # Setting the number of containers we want deployed to 2
  deployment_maximum_percent         = 300 # Maximum overprovisioning
  deployment_minimum_healthy_percent = 0 # Minimum instance (set this to 100 to avoid downtime in prod)

  load_balancer {
    target_group_arn = aws_lb_target_group.frontend.arn # Referencing our target group
    container_name   = aws_ecs_task_definition.frontend.family
    container_port   = 3000 # Specifying the container port
  }

  network_configuration {
    subnets = [
      aws_default_subnet.default_subnet_a.id,
      aws_default_subnet.default_subnet_b.id,
      aws_default_subnet.default_subnet_c.id
    ]
    assign_public_ip = true # Providing our containers with public IPs
  }

  depends_on = [aws_lb.application_load_balancer]

}

resource "aws_ecs_task_definition" "frontend" {
  family                   = "${var.app_name}-${var.environment}-frontend" # Naming our first task
  container_definitions    = <<DEFINITION
  [
    {
      "name": "${var.app_name}-${var.environment}-frontend",
      "image": "${aws_ecr_repository.frontend.repository_url}:${var.github_sha}",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 3000,
          "hostPort": 3000
        }
      ],
      "memory": 512,
      "cpu": 256,
      "environment": ${jsonencode(var.service_configuration.frontend.environment)},
      "secrets": ${jsonencode(var.service_configuration.frontend.secrets)},
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${aws_cloudwatch_log_group.frontend.name}",
          "awslogs-region": "${var.aws_region}",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
  DEFINITION
  requires_compatibilities = ["FARGATE"] # Stating that we are using ECS Fargate
  network_mode             = "awsvpc"    # Using awsvpc as our network mode as this is required for Fargate
  memory                   = 512         # Specifying the memory our container requires
  cpu                      = 256         # Specifying the CPU our container requires
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
}
