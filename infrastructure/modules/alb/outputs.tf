output "alb_dns_name" {
  value = aws_lb.alb.dns_name
}

output "target_group_arns" {
  value = { for k, tg in aws_lb_target_group.tg : k => tg.arn }
}

output "alb_sg_id" {
  value = aws_security_group.alb.id
}

# De ARN van de HTTPS listener (optioneel, maar handig voor debugging)
output "listener_arn" {
  value = aws_lb_listener.https.arn
}