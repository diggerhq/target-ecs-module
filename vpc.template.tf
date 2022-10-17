data "aws_vpc" "vpc" {
  id = var.vpc_id
}

locals {
  vpc = data.aws_vpc.vpc
}

# output the vpc ids
output "vpc_id" {
  value = data.aws_vpc.vpc.id
}

output "security_group_ids" {
  value = [aws_security_group.ecs_service_sg.id]
}