resource "aws_ecr_repository" "app" {
  name                 = var.ecs_service_name
  image_tag_mutability = var.image_tag_mutability
  force_delete         = true
}

