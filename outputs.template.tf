output "ecs_task_security_group_id" {
  value = aws_security_group.ecs_task_sg.id
}

{% if load_balancer %}

# The load balancer DNS name
output "lb_dns" {
  value = aws_alb.main.dns_name
}

output "lb_arn" {
  value = aws_alb.main.arn
}

output "lb_http_listener_arn" {
  value = try(aws_alb_listener.http.arn, null)
}

output "lb_zone_id" {
  value = aws_alb.main.zone_id
}

{% endif %}

output "docker_registry_url" {
  value = aws_ecr_repository.app.repository_url
}
