

resource "aws_security_group" "ecs_task_sg" {
  name        = "${var.ecs_cluster_name}-${var.ecs_service_name}-task"
  description = "Limit connections from internal resources while allowing ${var.ecs_cluster_name}-task to connect to all external resources"
  vpc_id      = var.vpc_id

  tags = var.tags
}

# Rules for the LB (Targets the task SG)

{% if load_balancer %}

resource "aws_security_group" "lb_sg" {
  name        = "${var.ecs_cluster_name}-${var.ecs_service_name}-lb"
  description = "Allow connections from external resources while limiting connections from ${var.ecs_cluster_name}-lb to internal resources"
  vpc_id      = var.vpc_id

  tags = var.tags
}

resource "aws_security_group_rule" "lb_egress_rule" {
  description              = "Only allow SG ${var.ecs_cluster_name}-lb to connect to ${var.ecs_cluster_name}-task on port ${var.container_port}"
  type                     = "egress"
  from_port                = var.container_port
  to_port                  = var.container_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ecs_task_sg.id
  security_group_id        = aws_security_group.lb_sg.id
}

# Rules for the TASK (Targets the LB SG)
resource "aws_security_group_rule" "ecs_task_ingress_rule" {
  for_each                 = toset(var.service_security_groups)
  description              = "Only allow connections from SG ${var.ecs_cluster_name}-lb on port ${var.container_port}"
  type                     = "ingress"
  from_port                = var.container_port
  to_port                  = var.container_port
  protocol                 = "tcp"
  source_security_group_id = each.value
  security_group_id = aws_security_group.ecs_task_sg.id
}

{% endif %}
resource "aws_security_group_rule" "ecs_task_egress_rule" {
  description = "Allows task to establish connections to all resources"
  type        = "egress"
  from_port   = "0"
  to_port     = "0"
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.ecs_task_sg.id
}

