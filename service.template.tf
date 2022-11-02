
locals {
  aws_app_identifier = "{{aws_app_identifier}}"
}

module "monitoring" {
  count = var.monitoring_enabled ? 1 : 0
  source = "./monitoring"
  ecs_cluster_name = aws_ecs_cluster.app.name
  ecs_service_name = local.aws_app_identifier
  alarms_sns_topic_arn = var.alarms_sns_topic_arn
  tags = var.tags
}

{% if tcp_service %}
  
  module "service" {
    source = "./fargate-service-tcp"

    ecs_cluster = aws_ecs_cluster.app
    service_name = local.aws_app_identifier
    region = var.region
    service_vpc = aws_vpc.vpc
    service_security_groups = []
    subnet_ids = var.public_subnets
    vpcCIDRblock = var.vpcCIDRblock
    {% if environment_variables %}
    environment_variables = jsondecode(<<EOT
        {{ environment_variables | tojson}}
EOT
    )
    {% endif %}

    {% if secret_keys %}
    secrets = [for secret_key in jsonencode(<<EOT
        {{ secret_keys | tojson }}
    EOT
    ): {
    name = aws_ssm_parameter.${secret_key}.name
    valueFrom = aws_ssm_parameter.${secret_key}.arn
    }]
    {% endif %}

    {%- if internal is defined %}
    internal={{ internal }}
    {%- endif %}

    health_check = "{{health_check}}"
    {% if health_check_interval %}
    health_check_interval = "{{health_check_interval}}"
    {% endif %}

    container_port = var.container_port
    container_name = local.aws_app_identifier
    launch_type = "{{launch_type}}"

    default_backend_image = "quay.io/turner/turner-defaultbackend:0.2.0"
    {% if task_cpu %}task_cpu = "{{task_cpu}}" {% endif %}
    {% if task_memory %}task_memory = "{{task_memory}}" {% endif %}
  }

  output "docker_registry_url" {
    value = module.service.docker_registry_url
  }

  output "lb_dns" {
    value = module.service.lb_dns
  }

{% elif load_balancer %}
  module "service" {
    source = "./module-fargate-service"

    ecs_cluster = aws_ecs_cluster.app
    service_name = local.aws_app_identifier
    region = var.region
    service_vpc = local.vpc
    service_security_groups = []
    subnet_ids = var.private_subnets

    {%- if internal is defined %}
    internal={{ internal }}
    {%- endif %}

    {% if environment_variables %}
    environment_variables = jsondecode(<<EOT
    {{ environment_variables | tojson}}
EOT
    )
    {% endif %}

    {% if secret_keys %}
    secrets = [for secret_key in jsonencode(<<EOT
    {{ secret_keys | tojson }}
EOT
): {
      name = aws_ssm_parameter.${secret_key}.name
      valueFrom = aws_ssm_parameter.${secret_key}.arn
    }]
    {% endif %}

    alb_internal = false
    alb_subnet_ids = var.public_subnets

    health_check = "{{health_check}}"

    {% if health_check_disabled %}
    health_check_enabled = false
    {% endif %}

    {% if health_check_grace_period_seconds %}
    health_check_grace_period_seconds = "{{health_check_grace_period_seconds}}"
    {% endif %}

    {% if lb_protocol %}
    lb_protocol = "{{lb_protocol}}"
    {% endif %}

    {% if health_check_matcher %}
    health_check_matcher = "{{health_check_matcher}}"
    {% endif %}

    {% if ecs_autoscale_min_instances %}
      ecs_autoscale_min_instances = "{{ecs_autoscale_min_instances}}"
    {% endif %}

    {% if ecs_autoscale_max_instances %}
      ecs_autoscale_max_instances = "{{ecs_autoscale_max_instances}}"
    {% endif %}

    container_port = var.container_port
    container_name = local.aws_app_identifier
    launch_type = "{{launch_type}}"

    default_backend_image = "quay.io/turner/turner-defaultbackend:0.2.0"
    tags = var.tags

    {% if lb_ssl_certificate_arn %}
      lb_ssl_certificate_arn = "{{lb_ssl_certificate_arn}}"
    {% endif %}

    {% if task_cpu %}task_cpu = "{{task_cpu}}" {% endif %}
    {% if task_memory %}task_memory = "{{task_memory}}" {% endif %}
  }


  {% if create_dns_record %} 
    resource "aws_route53_record" "r53" {
      zone_id = "{{dns_zone_id}}"
      name    = "{{aws_app_identifier}}.{{hostname}}"
      type    = "A"

      alias {
        name                   = module.service-{{aws_app_identifier}}.lb_dns
        zone_id                = module.service-{{aws_app_identifier}}.lb_zone_id
        evaluate_target_health = false
      }
    }

    output "custom_domain" {
        value = aws_route53_record.{{aws_app_identifier}}_r53.fqdn
    }

  {% endif %}

  output "docker_registry_url" {
    value = module.service.docker_registry_url
  }

  output "lb_dns" {
    value = module.service.lb_dns
  }

  output "lb_arn" {
    value = module.service.lb_arn
  }

  output "lb_http_listener_arn" {
    value = module.service.lb_http_listener_arn
  }

  output "ecs_task_security_group_id" {
    value = module.service.ecs_task_security_group_id
  }

{% else %}
  module "service" {
    source = "./module-fargate-service-nolb"

    ecs_cluster = aws_ecs_cluster.app
    service_name = local.aws_app_identifier
    region = var.region
    service_vpc = local.vpc
    subnet_ids = var.public_subnets

    {%- if internal is defined %}
    internal={{ internal }}
    {%- endif %}

    container_name = local.aws_app_identifier
    launch_type = "{{launch_type}}"
    default_backend_image = "quay.io/turner/turner-defaultbackend:0.2.0"
    tags = var.tags
    {% if task_cpu %}
    task_cpu = "{{task_cpu}}"
    {% endif %}
    {% if task_memory %}
    task_memory = "{{task_memory}}"
    {% endif %}

    {% if ecs_autoscale_min_instances %}
      ecs_autoscale_min_instances = "{{ecs_autoscale_min_instances}}"
    {% endif %}

    {% if ecs_autoscale_max_instances %}
      ecs_autoscale_max_instances = "{{ecs_autoscale_max_instances}}"
    {% endif %}

    {% if environment_variables %}
    environment_variables = jsondecode(<<EOT
            {{ environment_variables | tojson}}
EOT
    )
    {% endif %}

    {% if secret_keys %}
    secrets = [for secret_key in jsonencode(<<EOT
        {{ secret_keys | tojson }}
    EOT
    ): {
    name = aws_ssm_parameter.${secret_key}.name
    valueFrom = aws_ssm_parameter.${secret_key}.arn
    }]
    {% endif %}
  }

  output "docker_registry_url" {
    value = module.service.docker_registry_url
  }

  output "lb_dns" {
    value = ""
  }

{% endif %}



{% for secret_key in secret_keys %}
resource "aws_ssm_parameter" "{{secret_key}}" {
  name  = "/secrets/${var.ecs_cluster_name}/{{secret_key}}"
  type  = "SecureString"
  value = "REPLACE_ME"
  lifecycle {
      ignore_changes = [value]
    }
  }
{% endfor %}
