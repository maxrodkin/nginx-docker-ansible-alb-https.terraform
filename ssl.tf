resource "aws_iam_server_certificate" "this" {
  name_prefix      = "${local.name}-cert"
  certificate_body = file("${path.module}/ssl/public.pem")
  private_key      = file("${path.module}/ssl/private.pem")
  lifecycle {
    create_before_destroy = true
  }
}
