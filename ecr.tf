resource "aws_ecr_repository" "ecr_repo" {
  name                 = var.ecs_service_name
  image_tag_mutability = var.image_tag_mutability
  force_delete         = true
}

