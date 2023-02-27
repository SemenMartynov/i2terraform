variable "region" {
  description = "Select region for deploy"
  default     = "eu-north-1" # Stockholm
}

variable "instance_type" {
  description = "Instance Type"
  default     = "t3.micro" # 2vCPU, 1G
}

variable "allow_pors" {
  description = "List of the openned ports"
  type        = list(any)
  default     = [80, 443]
}

variable "common_tags" {
  description = "Common tags"
  type        = map(any)
  default = {
    Owner       = "Semen Martynov"
    Project     = "Highly Availble WebService"
    Environment = "prod"
  }
}
