terraform {
  backend "s3" {}
}

# --- 1. Security Group voor de Load Balancer ---
resource "aws_security_group" "alb" {
  name        = "pxl-${var.environment}-alb-sg"
  description = "Toegang vanaf internet op HTTPS"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Optioneel: voeg poort 80 toe voor testen mocht 443 nog lastig doen
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "pxl-${var.environment}-alb-sg" }
}

# --- 2. De Load Balancer ---
resource "aws_lb" "alb" {
  name               = "pxl-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids
}

# --- 3. Target Groups ---
locals {
  web_configs = {
    api      = { port = 3000, priority = 10, path = ["/api", "/api/*"] }
    media    = { port = 8081, priority = 20, path = ["/media", "/media/*"] }
    frontend = { port = 80,   priority = 30, path = ["/*"] } 
  }
}

resource "aws_lb_target_group" "tg" {
  for_each = local.web_configs

  name        = "tg-${var.environment}-${each.key}"
  port        = each.value.port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/health"
    port                = "traffic-port"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# --- 4. De HTTPS Listener (ZONDER de aws_acm_certificate resource) ---
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  
  # GEBRUIK DE VARIABELE (De ARN die je handmatig hebt geplakt in terragrunt.hcl)
  certificate_arn   = var.ssl_cert_arn 

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg["frontend"].arn
  }
}

# --- 5. Listener Rules (Path-based routing) ---
resource "aws_lb_listener_rule" "rules" {
  for_each = local.web_configs

  listener_arn = aws_lb_listener.https.arn
  priority     = each.value.priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg[each.key].arn
  }

  condition {
    path_pattern {
      values = each.value.path
    }
  }
}