variable "strip-path-prefix-proxy-appname" {
  type = string
  description = "The name of the app the proxy should point to"
}

locals {
  gateway_name      = "preview-proxy"
  custom_domainname = data.aws_cloudformation_export.domain_name.value
  certificate_arn   = module.cert_idealo_cloud.acm_certificate_arn
  zone_id           = data.aws_cloudformation_export.hosted_zone_id.value
  prefix            ="/offerpage-preview"

}

resource "aws_apigatewayv2_api" "strip-path-proxy" {
  name = local.gateway_name
  protocol_type = "HTTP"
  description = <<-EOM
    "The purpose of this Gateway is to have an endpoint that the Layer7 product can call.
    We strip off the path prefix here, because the application depends on `correct` paths."
  EOM
  disable_execute_api_endpoint = false
  target = "https://${var.strip-path-prefix-proxy-appname}.${local.custom_domainname}/{proxy}"
  route_key = "${local.prefix}/{proxy+}"
}

resource "aws_apigatewayv2_domain_name" "customdomain" {
  domain_name = "${local.gateway_name}.${local.custom_domainname}"

  domain_name_configuration {
    certificate_arn = local.certificate_arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}

resource "aws_route53_record" "example" {
  name    = aws_apigatewayv2_domain_name.customdomain.domain_name
  type    = "A"
  zone_id = local.zone_id

  alias {
    name                   = aws_apigatewayv2_domain_name.customdomain.domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.customdomain.domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }
}

