resource "aws_ecr_repository" "api" {
  name = "${var.app_name}-${var.environment}-api"
}

resource "aws_cloudwatch_log_group" "api" {
  name = "${var.app_name}-${var.environment}-api"
}

resource "aws_lb_target_group" "api" {
  name        = "${var.app_name}-${var.environment}-api"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_default_vpc.default_vpc.id # Referencing the default VPC
  health_check {
    matcher = "200,301,302"
    path    = "/${var.service_configuration.api.url_prefix}"
  }
  depends_on = [aws_lb.application_load_balancer]
}

resource "aws_lb_listener_rule" "api" {
  listener_arn = aws_lb_listener.listener_https.arn
  # important! route only api, and must override frontend path_pattern "/*"
  # Note: priority 1 -> first/highest priority vs. priority 99 -> low priority
  priority = 1
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }
  condition {
    path_pattern {
      values = ["/${var.service_configuration.api.url_prefix}*"]
    }
  }
}

resource "aws_service_discovery_service" "api" {
  name = "api"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.app.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }
  
  health_check_custom_config {
    failure_threshold = 1
  }
}

resource "aws_ecs_service" "api" {
  name            = "${var.app_name}-${var.environment}-api" # Naming our first service
  cluster         = aws_ecs_cluster.app.id                   # Referencing our created Cluster
  task_definition = aws_ecs_task_definition.api.arn          # Referencing the task our service will spin up
  launch_type     = "FARGATE"
  desired_count   = 2 # Setting the number of containers we want deployed to 2
  deployment_maximum_percent         = 300 # Maximum overprovisioning
  deployment_minimum_healthy_percent = 0 # Minimum instance (set this to 100 to avoid downtime in prod)

  load_balancer {
    target_group_arn = aws_lb_target_group.api.arn # Referencing our target group
    container_name   = aws_ecs_task_definition.api.family
    container_port   = 80 # Specifying the container port
  }

  network_configuration {
    subnets = [
      aws_default_subnet.default_subnet_a.id,
      aws_default_subnet.default_subnet_b.id,
      aws_default_subnet.default_subnet_c.id
    ]
    assign_public_ip = true # Providing our containers with public IPs
  }

  service_registries {
      registry_arn = aws_service_discovery_service.api.arn
      container_name = "api"
  }

  depends_on = [aws_lb.application_load_balancer]

}

resource "aws_ecs_task_definition" "api" {
  family                   = "${var.app_name}-${var.environment}-api" # Naming our first task
  container_definitions    = <<DEFINITION
  [
    {
      "name": "${var.app_name}-${var.environment}-api",
      "image": "${aws_ecr_repository.api.repository_url}:${var.github_sha}",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 80,
          "hostPort": 80
        }
      ],
      "memory": 512,
      "cpu": 256,
      "environment": ${jsonencode(var.service_configuration.api.environment)},
      "secrets": ${jsonencode(var.service_configuration.api.secrets)},
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${aws_cloudwatch_log_group.api.name}",
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
