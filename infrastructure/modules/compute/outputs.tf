# Toont aan dat het cluster is aangemaakt
output "ecs_cluster_name" {
  description = "De naam van het ECS cluster"
  value       = aws_ecs_cluster.main.name
}

# Belangrijk voor debugging en service verificatie
output "service_names" {
  description = "Lijst van draaiende services"
  value       = [for s in aws_ecs_service.services : s.name]
}

# Bewijs van EFS (Shared Storage)
output "efs_id" {
  description = "ID van het gedeelde bestandssysteem"
  value       = aws_efs_file_system.media.id
}

# De Task Execution Role ARN (handig voor auditing/security)
output "execution_role_arn" {
  description = "De IAM role die de containers gebruiken om logs/secrets te laden"
  value       = aws_iam_role.ecs_task_execution_role.arn
}