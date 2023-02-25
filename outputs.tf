output "webserver_instance_id" {
  value = aws_instance.my_webserver.id
  description = "WebServer instance ID"
}

output "webserver_public_ip_address" {
  value = aws_eip.webserver_static_ip.public_ip
  description = "WebServer public IP"
}

output "webserver_sg_id" {
  value = aws_security_group.my_webserver.id
  description = "WebServer Security Group ID"
}

output "webserver_sg_arn" {
  value = aws_security_group.my_webserver.arn
  description = "WebServer Security Group ARN"
}