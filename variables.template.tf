/*
 * variables.template.tf
 * Common variables to use in various Terraform files (*.tf)
 */

# The AWS region to use for the dev environment's infrastructure
variable "region" {
  default = "us-east-1"
}

variable "vpc_id" {
}

# Tags for the infrastructure
variable "tags" {
  type = map(string)
}

# ecs derived variable names
variable "ecs_cluster_name" {}

variable "ecs_service_name" {}

variable "alarms_actions" {
  default = []
}

variable "ok_actions" {
  default = []
}

# Network configuration

variable "container_port" {
}

# The tag mutability setting for the repository (defaults to IMMUTABLE)
variable "image_tag_mutability" {
  type        = string
  default     = "MUTABLE"
  description = "The tag mutability setting for the repository (defaults to IMMUTABLE)"
}

variable "service_security_groups" {
  default = []
}

# === Load Balancer ===

# The loadbalancer subnets

variable "alb_subnet_ids" {}

variable "ecs_subnet_ids" {}

# The port the load balancer will listen on
variable "lb_port" {
  default = "80"
}

# The load balancer protocol
variable "lb_protocol" {
  default = "HTTP"
}

variable "lb_ssl_port" {
  default = "443"
}

variable "lb_ssl_protocol" {
  default = "HTTPS"
}

variable "lb_ssl_certificate_arn" {
  default = null
}

# Whether the application is available on the public internet,
# also will determine which subnets will be used (public or private)
variable "internal" {
  default = true
}

variable "alb_internal" {
  default = false
}

# The amount time for Elastic Load Balancing to wait before changing the state of a deregistering target from draining to unused
variable "deregistration_delay" {
  default = "30"
}

# The path to the health check for the load balancer to know if the container(s) are ready
variable "health_check" {
  default = "/"
}

variable "health_check_enabled" {
  default = true
}

# How often to check the liveliness of the container
variable "health_check_interval" {
  default = "30"
}

# How long to wait for the response on the health check path
variable "health_check_timeout" {
  default = "10"
}

variable "health_check_grace_period_seconds" {
  default = "1"
}

# What HTTP response code to listen for
variable "health_check_matcher" {
  default = "200-499"
}

variable "lb_access_logs_expiration_days" {
  default = "3"
}


# The port the container will listen on, used for load balancer health check
# Best practice is that this value is higher than 1024 so the container processes
# isn't running at root.

variable "launch_type" {
  default = "FARGATE"
}

# The minimum number of containers that should be running.
# Must be at least 1.
# used by both autoscale-perf.tf and autoscale.time.tf
# For production, consider using at least "2".
variable "ecs_autoscale_min_instances" {
  default = "1"
}

# The maximum number of containers that should be running.
# used by both autoscale-perf.tf and autoscale.time.tf
variable "ecs_autoscale_max_instances" {
  default = "8"
}

variable "task_cpu" {
  default = "256"
}

variable "task_memory" {
  default = "512"
}

# == for EFS ==
variable "volumes" {
  default = []
}

variable "mountPoints" {
  default = []
  type = list(object({
    path = string
    volume  = string
  }))
}

variable "environment_variables" {
  default = []
  type = list(object({
    key = string
    value  = any
  }))
}

variable "secrets" {
  default = []
  type = list(object({
    key = string
    value  = any
  }))
}

# == Cloudwatch ==

variable "logs_retention_in_days" {
  type        = number
  default     = 14
  description = "Specifies the number of days you want to retain log events"
}

{% if lb_monitoring_enabled %}

variable "target_3xx_count_threshold" {
  default = 5
}

variable "target_4xx_count_threshold" {
  default = 5
}

variable "target_5xx_count_threshold" {
  default = 5
}

variable "elb_5xx_count_threshold" {
  default = 5
}

variable "target_response_time_threshold" {
  default = 1
}
{% endif %}

{% if monitoring_enabled %}

variable "cpu_utilization_high_threshold" {
  default = 80
}

variable "memory_utilization_high_threshold" {
  default = 100
}

variable "cpu_utilization_high_evaluation_periods" {
  default = 1
}

variable "cpu_utilization_high_period" {
  default = 60
}

variable "memory_utilization_high_evaluation_periods" {
  default = 1
}

variable "memory_utilization_high_period" {
  default = 60
}

{% endif %}