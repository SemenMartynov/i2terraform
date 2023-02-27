output "web_load_balancer_url" {
  value = aws_elb.web.dns_name
}

output "webserver_sg_id" {
  value = aws_security_group.webserver.id
  description = "WebServer Security Group ID"
}

output "webserver_sg_arn" {
  value = aws_security_group.webserver.arn
  description = "WebServer Security Group ARN"
}
