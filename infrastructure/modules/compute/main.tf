# --- 1. IAM Roles voor ECS ---
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "pxl-${var.environment}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Extra permissies om secrets te lezen uit SSM/Secrets Manager
resource "aws_iam_role_policy" "secrets_policy" {
  name = "pxl-${var.environment}-secrets-policy"
  role = aws_iam_role.ecs_task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["ssm:GetParameters", "secretsmanager:GetSecretValue"]
      Resource = ["*"]
    }]
  })
}

# --- 2. Shared Storage (EFS) ---
resource "aws_efs_file_system" "media" {
  creation_token = "pxl-${var.environment}-media"
  encrypted      = true
  tags           = { Name = "pxl-${var.environment}-efs" }
}

resource "aws_efs_mount_target" "media_mount" {
  count           = length(var.private_subnet_ids)
  file_system_id  = aws_efs_file_system.media.id
  subnet_id       = var.private_subnet_ids[count.index]
  security_groups = [aws_security_group.efs_sg.id]
}

# --- 3. ECS Cluster ---
resource "aws_ecs_cluster" "main" {
  name = "pxl-${var.environment}-cluster"
}

# --- 4. Task Definitions (De Loop) ---
resource "aws_ecs_task_definition" "tasks" {
  for_each = toset(var.services)

  family                   = "pxl-${var.environment}-${each.key}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([{
    name  = each.key
    image = "pxlcensor/${each.key}:latest" # Pas aan naar jouw ECR/DockerHub
    
    portMappings = [{
      containerPort = (each.key == "api" ? 3000 : each.key == "media" ? 8081 : each.key == "frontend" ? 8080 : 80)
      hostPort      = (each.key == "api" ? 3000 : each.key == "media" ? 8081 : each.key == "frontend" ? 8080 : 80)
    }]

    environment = [
      { name = "BASE_URL", value = var.base_url },
      { name = "DATABASE_URL", value = "postgres://postgres@${var.db_endpoint}/pxlcensor" }
    ]

    secrets = [
      { name = "MEDIA_SIGNING_SECRET", valueFrom = var.media_secret_arn },
      { name = "POSTGRES_PASSWORD", valueFrom = var.db_secret_arn }
    ]

    mountPoints = [{
      sourceVolume  = "media-data"
      containerPath = "/app/media-data"
      readOnly      = false
    }]
  }])

  volume {
    name = "media-data"
    efs_volume_configuration {
      file_system_id = aws_efs_file_system.media.id
    }
  }
}

# --- 5. ECS Services ---
resource "aws_ecs_service" "services" {
  for_each        = toset(var.services)
  name            = "pxl-${var.environment}-${each.key}"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.tasks[each.key].arn
  launch_type     = "FARGATE"
  desired_count   = 1 # Start altijd met 1

  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [aws_security_group.app_sg.id]
  }

  # Alleen koppelen aan ALB als het geen processor is
  dynamic "load_balancer" {
    for_each = contains(["frontend", "api", "media"], each.key) ? [1] : []
    content {
      target_group_arn = var.target_group_arns[each.key]
      container_name   = each.key
      container_port   = (each.key == "api" ? 3000 : each.key == "media" ? 8081 : 8080)
    }
  }
}

# --- 6. Autoscaling (De Conditional) ---
resource "aws_appautoscaling_target" "api_processor_scale" {
  # Pas autoscaling alleen toe op api en processor in PROD
  for_each = (var.environment == "prod" && var.autoscale) ? toset(["api", "processor"]) : toset([])

  max_capacity       = 2
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.services[each.key].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}