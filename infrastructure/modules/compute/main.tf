terraform {
  backend "s3" {}
}

# --- 1. IAM Role (Academy Fix) ---
data "aws_iam_role" "lab_role" {
  name = "LabRole"
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

# --- 4. Task Definitions ---
resource "aws_ecs_task_definition" "tasks" {
  for_each = toset(var.services)

  family                   = "pxl-${var.environment}-${each.key}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = data.aws_iam_role.lab_role.arn
  task_role_arn            = data.aws_iam_role.lab_role.arn

  container_definitions = jsonencode([{
    name  = each.key
    image = "pxlcensor/${each.key}:latest"
    
    portMappings = [{
      # CORRECTIE: Frontend op 80, Media op 8081, API op 3000
      containerPort = (each.key == "api" ? 3000 : each.key == "media" ? 8081 : 80)
      hostPort      = (each.key == "api" ? 3000 : each.key == "media" ? 8081 : 80)
    }]

    environment = [
      { name = "BASE_URL", value = var.base_url },
      # TIP: Gebruik de DB Host uit de module
      { name = "DATABASE_URL", value = "postgres://postgres@${var.db_endpoint}/pxlcensor" }
    ]

    secrets = [
      { name = "MEDIA_SIGNING_SECRET", valueFrom = var.media_secret_arn },
      { name = "POSTGRES_PASSWORD",    valueFrom = var.db_secret_arn }
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
  desired_count   = 1

  # CRUCIAAL: Wacht tot EFS klaar is voor de containers starten
  depends_on = [aws_efs_mount_target.media_mount]

  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [aws_security_group.app_sg.id]
  }

  dynamic "load_balancer" {
    for_each = contains(["frontend", "api", "media"], each.key) ? [1] : []
    content {
      target_group_arn = var.target_group_arns[each.key]
      container_name   = each.key
      container_port   = (each.key == "api" ? 3000 : each.key == "media" ? 8081 : 80)
    }
  }
}

# --- 6. Autoscaling (Eis: PROD min 1, max 2) ---
resource "aws_appautoscaling_target" "scaling" {
  # 'media' is de service die de processing doet
  for_each = (var.environment == "prod") ? toset(["api", "media"]) : toset([])

  max_capacity       = 2
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.services[each.key].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# --- 7. Security Groups ---
resource "aws_security_group" "app_sg" {
  name        = "pxl-${var.environment}-app-sg"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [var.alb_sg_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "efs_sg" {
  name   = "pxl-${var.environment}-efs-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}