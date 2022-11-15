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

{% if monitoring_enabled %}
output "monitoring_alarms" {
  value = [aws_cloudwatch_metric_alarm.cpu_utilization_high.name, aws_cloudwatch_metric_alarm.memory_utilization_high.name]
}
{% endif %}

{% if lb_monitoring_enabled %}
output "lb_monitoring_alarms" {
  value = [aws_cloudwatch_metric_alarm.http_code_target_3xx_count_high.name,
  aws_cloudwatch_metric_alarm.http_code_target_4xx_count_high.name,
  aws_cloudwatch_metric_alarm.http_code_target_5xx_count_high.name,
  aws_cloudwatch_metric_alarm.http_code_elb_5xx_count_high.name,
  aws_cloudwatch_metric_alarm.target_response_time_average_high.name,
]
}
{% endif %}