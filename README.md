This template is a fork of https://github.com/turnerlabs/terraform-ecs-fargate and has been modified from its original state


Jinja parameters:


parameters controlling behaviour (Booleans):
monitoring_enabled
lb_monitoring_enabled
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



variable "region" 
variable "vpc_id" 
variable "tags" 
variable "ecs_cluster_name" 
variable "ecs_service_name"
variable "alarms_actions" 
variable "ok_actions" 

{% if load_balancer %}
variable "container_port" 
{% endif %}

# The tag mutability setting for the repository (defaults to IMMUTABLE)
variable "image_tag_mutability" 
variable "service_security_groups"
variable "alb_subnet_ids" 
variable "ecs_subnet_ids" 
variable "lb_port" 
variable "lb_protocol" 
variable "lb_ssl_port" 
variable "lb_ssl_protocol" 
variable "lb_ssl_certificate_arn" 
variable "internal" 
variable "alb_internal" 
variable "deregistration_delay" 
variable "health_check"
variable "health_check_enabled"
variable "health_check_interval" 
variable "health_check_timeout" 
variable "health_check_grace_period_seconds" 
variable "health_check_matcher" 
variable "lb_access_logs_expiration_days" 
variable "launch_type" 
variable "ecs_autoscale_min_instances" 
variable "ecs_autoscale_max_instances" 
variable "task_cpu" 
variable "task_memory" 
variable "volumes"
variable "mountPoints" 
variable "environment_variables" 
variable "secrets"

# == Cloudwatch ==

variable "logs_retention_in_days"

{% if monitoring_enabled and load_balancer %}
variable "target_3xx_count_threshold"
variable "target_4xx_count_threshold" 
variable "target_5xx_count_threshold" 
variable "elb_5xx_count_threshold" 
variable "target_response_time_threshold" 
{% endif %}

{% if monitoring_enabled %}
variable "cpu_utilization_high_threshold"
variable "memory_utilization_high_threshold" 
variable "cpu_utilization_high_evaluation_periods"
variable "cpu_utilization_high_period" 
variable "memory_utilization_high_evaluation_periods"
variable "memory_utilization_high_period" 
{% endif %}

{% if datadog_enabled %}
variable "datadog_key_ssm_arn" 
{% endif %}