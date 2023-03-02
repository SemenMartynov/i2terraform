variable "region" {
  description = "Select region for deploy"
  default     = "eu-north-1" # Stockholm
}

variable "instance_type" {
  description = "Instance Type"
  default     = "t3.micro" # 2vCPU, 1G
}

variable "common_tags" {
  description = "Common tags"
  type        = map(any)
  default = {
    Owner       = "Semen Martynov"
    Project     = "ALB with basic-auth protected web-service"
  }
}

variable "ec2ic_user" {
  description = "User for EC2 instance connect"
  default = "7586-6299-5363"
}