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
  awsloggroup     = "/ecs/service/${var.service_name}"
  container_image = aws_ecr_repository.app.repository_url
}

resource "aws_appautoscaling_target" "app_scale_target" {
  service_namespace  = "ecs"
  resource_id        = "service/${var.ecs_cluster.name}/${aws_ecs_service.app.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  max_capacity       = var.ecs_autoscale_max_instances
  min_capacity       = var.ecs_autoscale_min_instances
}

resource "aws_ecs_task_definition" "app" {
  family                   = var.container_name
  requires_compatibilities = [var.launch_type]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn

  task_role_arn = aws_iam_role.ecs_task_role.arn

  container_definitions = <<EOT
[
  {
    "name": "${var.container_name}",
    "image": "${local.container_image}",
    "essential": true,
    "portMappings": [
      {
        "protocol": "tcp",
        "containerPort": ${var.container_port},
        "hostPort": ${var.container_port}
      }
    ],
    "environment": ${var.task_definition_environment},
    "secrets" : ${var.task_definition_secrets},
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${local.awsloggroup}",
        "awslogs-region": "${var.region}",
        "awslogs-stream-prefix": "ecs"
      }
    }
  }
]
EOT

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
  name                              = var.service_name
  cluster                           = var.ecs_cluster.id
  launch_type                       = var.launch_type
  task_definition                   = aws_ecs_task_definition.app.arn
  desired_count                     = var.ecs_autoscale_min_instances
  health_check_grace_period_seconds = var.health_check_grace_period_seconds

  network_configuration {
    security_groups  = concat([aws_security_group.ecs_task_sg.id], var.service_security_groups)
    subnets          = var.subnet_ids
    assign_public_ip = !var.internal
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.main.id
    container_name   = var.container_name
    container_port   = var.container_port
  }

  # workaround for https://github.com/hashicorp/terraform/issues/12634
  depends_on = [aws_alb_listener.http]
}

# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_execution_IAM_role.html
resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "${var.ecs_cluster.name}-${var.service_name}-ecs"
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
  name               = "${var.service_name}_task_role"
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

resource "aws_iam_role_policy" "ecs_task_role_policy" {
  name   = "${var.service_name}_task_role_policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ssm:Describe*",
        "ssm:Get*",
        "ssm:List*"
      ],
      "Resource": "*"
    }
  ]
}
EOF

  role   = aws_iam_role.ecs_task_role.id
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = aws_iam_role.ecsTaskExecutionRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# provide access to read SSM secrets
resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_ssm_policy" {
  role       = aws_iam_role.ecsTaskExecutionRole.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
}


resource "aws_cloudwatch_log_group" "logs" {
  name              = local.awsloggroup
  retention_in_days = var.logs_retention_in_days
  tags              = var.tags
}
