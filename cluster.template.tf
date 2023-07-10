{% if shared_ecs_cluster is defined and shared_ecs_cluster %}
  data "aws_ecs_cluster" "ecs_cluster" {
    cluster_name = "{{shared_ecs_cluster_name}}"
  }
{% else %}
resource "aws_ecs_cluster" "ecs_cluster" {
  name = var.ecs_cluster_name
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  tags = var.tags
}
{% endif %}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.ecs_cluster.name
}