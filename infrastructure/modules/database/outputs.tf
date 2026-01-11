output "db_endpoint" {
  value = aws_db_instance.postgres.endpoint
}

output "db_security_group_id" {
  value = aws_security_group.db.id
}

output "db_secret_arn" {
  value = aws_secretsmanager_secret.db_secret.arn
}

output "media_secret_arn" {
  value = aws_secretsmanager_secret.media_secret.arn
}