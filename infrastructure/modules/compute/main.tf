provider "aws" {
  region = var.region
}

# Example: ECS Cluster
resource "aws_ecs_cluster" "pxlcensor" {
  name = "${var.environment}-pxlcensor-cluster"
}

# Loop over services
resource "aws_ecs_task_definition" "tasks" {
  for_each = toset(var.services)

  family                   = "${var.environment}-${each.key}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"

  container_definitions = jsonencode([{
    name      = each.key
    image     = "pxlcensor/${each.key}:latest"
    essential = true
    environment = [
      { name = "BASE_URL", value = var.base_url },
      { name = "MEDIA_SIGNING_SECRET", valueFrom = var.media_secret_arn },
      { name = "POSTGRES_PASSWORD", valueFrom = var.db_secret_arn }
    ]
    portMappings = [{
      containerPort = 80
      hostPort      = 80
    }]
  }])
}

# Autoscaling example (conditional)
resource "aws_appautoscaling_target" "service" {
  count              = var.autoscale ? length(var.services) : 0
  max_capacity       = 2
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.pxlcensor.name}/${aws_ecs_service.services[count.index].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}
