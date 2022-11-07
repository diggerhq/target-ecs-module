This template is a fork of https://github.com/turnerlabs/terraform-ecs-fargate and has been modified from its original state


Jinja parameters:


parameters controlling behaviour (Booleans):
is_monitoring_enabled
is_lb_monitoring_enabled
tcp_service
load_balancer
auto_scaling_enabled

Parameters to be injected into files (Strings):

aws_app_identifier
internal
health_check
container_port
launch_type
task_cpu
task_memory
tcp_service 
health_check_matcher
environment_config.health_check_interval
environment_config.health_check_grace_period_seconds
environment_config.lb_protocol
environment_config.ecs_autoscale_min_instances
environment_config.ecs_autoscale_max_instances
environment_config.lb_ssl_certificate_arn
environment_config.dns_zone_id
environment_config.hostname
