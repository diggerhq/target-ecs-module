{% if load_balancer %}

resource "aws_alb" "main" {
  name = var.service_name

  # launch lbs in public or private subnets based on "internal" variable
  internal        = var.alb_internal
  subnets         = var.alb_subnet_ids
  security_groups = [aws_security_group.lb_sg.id]
  tags            = var.tags

  # enable access logs in order to get support from aws
  access_logs {
    enabled = true
    bucket  = aws_s3_bucket.lb_access_logs.bucket
  }
}

resource "aws_alb_target_group" "main" {
  name                 = var.service_name
  port                 = var.lb_port
  protocol             = var.lb_protocol
  vpc_id               = var.service_vpc.id
  target_type          = "ip"
  deregistration_delay = var.deregistration_delay

  health_check {
    enabled             = var.health_check_enabled
    path                = var.health_check
    matcher             = var.health_check_matcher
    protocol            = var.lb_protocol
    interval            = var.health_check_interval
    timeout             = var.health_check_timeout
    healthy_threshold   = 5
    unhealthy_threshold = 5
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = var.tags
}

data "aws_elb_service_account" "main" {
}

# bucket for storing ALB access logs
resource "aws_s3_bucket" "lb_access_logs" {
  bucket_prefix = var.service_name
  tags          = var.tags
  force_destroy = true
}

resource "aws_s3_bucket_acl" "lb_access_logs_acl" {
  bucket = aws_s3_bucket.lb_access_logs.id
  acl    = "private"
}

resource "aws_s3_bucket_lifecycle_configuration" "lb_access_logs_lifecycle_rule" {
  bucket = aws_s3_bucket.lb_access_logs.id

  rule {
    id     = "cleanup"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
    expiration {
      days = var.lb_access_logs_expiration_days
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "lb_access_logs_server_side_encryption" {
  bucket = aws_s3_bucket.lb_access_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# give load balancing service access to the bucket
resource "aws_s3_bucket_policy" "lb_access_logs" {
  bucket = aws_s3_bucket.lb_access_logs.id

  policy = <<POLICY
{
  "Id": "Policy",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:PutObject"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.lb_access_logs.arn}",
        "${aws_s3_bucket.lb_access_logs.arn}/*"
      ],
      "Principal": {
        "AWS": [ "${data.aws_elb_service_account.main.arn}" ]
      }
    }
  ]
}
POLICY
}

# adds an http listener to the load balancer and allows ingress
# (delete this file if you only want https)

resource "aws_alb_listener" "http" {
  load_balancer_arn = aws_alb.main.id
  port              = var.lb_port
  protocol          = var.lb_protocol

  default_action {
    target_group_arn = aws_alb_target_group.main.id
    type             = "forward"
  }

  lifecycle {
    ignore_changes = [port, protocol, default_action]
  }
}

resource "aws_lb_listener" "https" {
  count = var.lb_ssl_certificate_arn==null ? 0 : 1
  load_balancer_arn = aws_alb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.lb_ssl_certificate_arn
  default_action {
    target_group_arn = aws_alb_target_group.main.id
    type             = "forward"
  }
}

resource "aws_lb_listener_certificate" "lb_listener_cert" {
   count = var.lb_ssl_certificate_arn==null ? 0 : 1
   listener_arn = aws_lb_listener.https[0].arn
   certificate_arn   = var.lb_ssl_certificate_arn
}

resource "aws_security_group_rule" "ingress_lb_http" {
  type              = "ingress"
  description       = var.lb_protocol
  from_port         = var.lb_port
  to_port           = var.lb_port
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.lb_sg.id
}

resource "aws_security_group_rule" "ingress_lb_https" {
  type              = "ingress"
  description       = var.lb_ssl_protocol
  from_port         = var.lb_ssl_port
  to_port           = var.lb_ssl_port
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.lb_sg.id
}

{% endif %}