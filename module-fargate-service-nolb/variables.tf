
variable "ecs_cluster" {}

variable "service_name" {}

# The tag mutability setting for the repository (defaults to IMMUTABLE)
variable "image_tag_mutability" {
  type        = string
  default     = "MUTABLE"
  description = "The tag mutability setting for the repository (defaults to IMMUTABLE)"
}

variable "service_vpc" {}

variable "region" {}

variable "tags" {}

# === Load Balancer ===

# The loadbalancer subnets
variable "subnet_ids" {}

# Whether the application is available on the public internet,
# also will determine which subnets will be used (public or private)
variable "internal" {
  default = true
}


# === Container ===



# The port the container will listen on, used for load balancer health check
# Best practice is that this value is higher than 1024 so the container processes
# isn't running at root.


# How many containers to run
variable "replicas" {
  default = "1"
}

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

variable "task_cpu" {
  default = "256"
}

variable "task_memory" {
  default = "512"
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
  default     = 90
  description = "Specifies the number of days you want to retain log events"
}
