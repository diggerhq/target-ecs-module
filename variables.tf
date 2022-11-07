/*
 * variables.tf
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

# The application's name
variable "app" {
}

# ecs derived variable names
variable "ecs_cluster_name" {}

variable "ecs_service_name" {}

variable "alarms_sns_topic_arn" {}

variable "monitoring_enabled" {}

# Network configuration

# The private subnets, minimum of 2, that are a part of the VPC(s)
variable "private_subnets" {
}

# The public subnets, minimum of 2, that are a part of the VPC(s)
variable "public_subnets" {
}

variable "container_port" {
}

variable "ecs_task_policy_json" {
}

variable "ecs_task_execution_policy_json" {
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



# === Container ===



# The port the container will listen on, used for load balancer health check
# Best practice is that this value is higher than 1024 so the container processes
# isn't running at root.


# The name of the container to run
variable "container_name" {
}

variable "launch_type" {
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

# The default docker image to deploy with the infrastructure.
# Note that you can use the fargate CLI for application concerns
# like deploying actual application images and environment variables
# on top of the infrastructure provisioned by this template
# https://github.com/turnerlabs/fargate
# note that the source for the turner default backend image is here:
# https://github.com/turnerlabs/turner-defaultbackend
variable "default_backend_image" {
  default = "quay.io/turner/turner-defaultbackend:0.2.0"
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


variable "secret_keys" {
  default = []
  type = set(string)
}

# == Cloudwatch ==

variable "logs_retention_in_days" {
  type        = number
  default     = 14
  description = "Specifies the number of days you want to retain log events"
}
