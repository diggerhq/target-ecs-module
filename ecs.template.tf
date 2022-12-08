/**
 * Elastic Container Service (ecs)
 * This component is required to create the ECS service. It will create a cluster
 * based on the application name and enironment. It will create a "Task Definition", which is required
 * to run a Docker container, https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definitions.html.
 * Next it creates a ECS Service, https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_services.html
 * It attaches the Load Balancer created in `lb.tf` to the service, and sets up the networking required.
 * It also creates a role with the correct permissions. And lastly, ensures that logs are captured in CloudWatch.
 *
 * When building for the first time, it will install a "default backend", which is a simple web service that just
 * responds with a HTTP 200 OK. It's important to uncomment the lines noted below after you have successfully
 * migrated the real application containers to the task definition.
 */

locals {
  awsloggroup     = "/ecs/service/${var.ecs_service_name}"
  container_image = aws_ecr_repository.ecr_repo.repository_url
}

resource "aws_appautoscaling_target" "app_scale_target" {
  service_namespace  = "ecs"
  resource_id        = "service/${var.ecs_cluster_name}/${aws_ecs_service.app.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  max_capacity       = var.ecs_autoscale_max_instances
  min_capacity       = var.ecs_autoscale_min_instances
}

resource "aws_ecs_task_definition" "app" {
  family                   = var.ecs_service_name
  requires_compatibilities = [var.launch_type]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  task_role_arn = aws_iam_role.ecs_task_role.arn
  container_definitions = jsonencode([{
  name      = var.ecs_service_name
  image     = "${aws_ecr_repository.ecr_repo.repository_url}:latest"
  essential = true
  portMappings = [{
    protocol      = "tcp"
    containerPort = var.container_port
    hostPort      = var.container_port
  }]
  environment = concat([
    {
      name  = "PORT"
      value = tostring(var.container_port)
    },
    {
      name  = "HEALTHCHECK"
      value = tostring(var.health_check)
    }
  ],
    [for e in var.environment_variables : {
      name  = e.key
      value = tostring(e.value)
    }])

    secrets = [for s in var.secrets : {
      name      = s.key
      valueFrom = s.value
    }]

  logConfiguration = {
    logDriver = "awslogs"
    options = {
      "awslogs-group"         = local.awsloggroup
      "awslogs-region"        = var.region
      "awslogs-stream-prefix" = "ecs"
    }
  }
  mountPoints = [for mountPoint in var.mountPoints: {
    containerPath = mountPoint.path
    sourceVolume  = mountPoint.volume
  }]
  }])

  dynamic "volume" {
    for_each = var.volumes
    content {
      name = volume.value.name

      efs_volume_configuration {
        file_system_id     = volume.value.file_system_id
        root_directory     = "/"
        transit_encryption = "ENABLED"
      }
    }
  }

  tags = var.tags
}

resource "aws_ecs_service" "app" {
  name                              = var.ecs_service_name
  cluster                           = aws_ecs_cluster.ecs_cluster.id
  launch_type                       = var.launch_type
  task_definition                   = aws_ecs_task_definition.app.arn
  desired_count                     = var.ecs_autoscale_min_instances
  health_check_grace_period_seconds = var.health_check_grace_period_seconds

  network_configuration {
    security_groups  = concat([aws_security_group.ecs_task_sg.id], var.service_security_groups)
    subnets          = var.ecs_subnet_ids
    assign_public_ip = !var.internal
  }

  {% if load_balancer %}
  load_balancer {
    target_group_arn = aws_alb_target_group.main.id
    container_name   = var.ecs_service_name
    container_port   = var.container_port
  }
  {% endif %}

  # workaround for https://github.com/hashicorp/terraform/issues/12634
  #depends_on = [aws_alb_listener.]
}

# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_execution_IAM_role.html
resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${var.ecs_cluster_name}-task-exec-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_role" {
  name               = "${var.ecs_service_name}-task-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

}

resource "aws_iam_policy" "ecs_task_execution_policy" {
  policy = file("${path.module}/ecs_task_execution_policy.json")
}

resource "aws_iam_policy" "ecs_task_policy" {
  policy = file("${path.module}/ecs_task_policy.json")
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_task_execution_policy.arn
}

resource "aws_iam_role_policy_attachment" "ecs_task_policy_attachment" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_task_policy.arn
}

resource "aws_cloudwatch_log_group" "logs" {
  name              = local.awsloggroup
  retention_in_days = var.logs_retention_in_days
  tags              = var.tags
}

