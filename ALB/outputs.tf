output "webserver_ip" {
  value = module.load-balancer.lb_dns_name
  description = "DNS name"
}
