# ------------------------------------------------------------------------------
# -                                                                            -
# -              ALB with basic-auth protected web-service                     -
# -                                                                            -
# ------------------------------------------------------------------------------

provider "aws" {
  region = var.region
}

# ------------------------------------------------------------------------------
# - Security Groups for Web Server                                             -
# ------------------------------------------------------------------------------

resource "aws_security_group" "webserver_sg" {
  name_prefix = "http_connect"
  description = "Allow http(s)"

  vpc_id = module.vpc.vpc_id

  dynamic "ingress" {
    for_each = [80, 443]
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "HTTP(s) connect Security Group"
  })
}

resource "aws_security_group" "ssh_connect_sg" {
  name_prefix = "ssh_connect"
  description = "Allow ssh"

  vpc_id = module.vpc.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    #cidr_blocks = var.ssh_list
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "SSH connect Security Group"
  })
}

# ------------------------------------------------------------------------------
# - Web Server Instance with Docker and basic auth                             -
# ------------------------------------------------------------------------------

data "aws_ami" "latest_amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-*-gp2"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_instance" "webserver" {
  ami           = data.aws_ami.latest_amazon_linux.id
  instance_type = var.instance_type
  count         = 1
  user_data     = file("scripts/init.sh")

  availability_zone = element(module.vpc.azs, 0)
  subnet_id         = element(module.vpc.public_subnets, 0)

  vpc_security_group_ids = [aws_security_group.webserver_sg.id, aws_security_group.ssh_connect_sg.id]
  //iam_instance_profile   = aws_iam_instance_profile.instance_connect.name
  key_name = "temp"

  provisioner "file" {
    source      = "files/default.conf"
    destination = "/tmp/default.conf"
  }

  provisioner "file" {
    source      = "scripts/init.sh"
    destination = "/tmp/init.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/init.sh",
      "/tmp/init.sh",
    ]
  }

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("keys/secret.pem")
    host        = self.public_ip
  }

  lifecycle {
    //prevent_destroy = true
    //ignore_changes = ["ami", "user_data"]
    create_before_destroy = true
  }

  tags = merge(var.common_tags, {
    Name = "ALB test Security Group"
  })
}


# ------------------------------------------------------------------------------

data "aws_availability_zones" "available" {}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name   = "VPC"
  cidr   = "10.0.0.0/16"

  azs            = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1]]
  public_subnets = ["10.0.1.0/24", "10.0.2.0/24"]

  enable_nat_gateway   = false
  enable_vpn_gateway   = false
  enable_dns_hostnames = true

  map_public_ip_on_launch = true

  tags = {
    Terraform = "true"
  }
}

module "load-balancer" {
  source = "terraform-aws-modules/alb/aws"

  name               = "LoadBalancer"
  vpc_id             = module.vpc.vpc_id
  subnets            = module.vpc.public_subnets
  load_balancer_type = "application"

  security_groups = [aws_security_group.webserver_sg.id]
  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]

  target_groups = [
    {
      name_prefix          = "h1"
      backend_protocol     = "HTTP"
      backend_port         = 80
      target_type          = "instance"
      deregistration_delay = 300
      health_check = {
        enabled             = true
        interval            = 5
        path                = "/health-check"
        port                = "traffic-port"
        healthy_threshold   = 2
        unhealthy_threshold = 2
        timeout             = 2
        protocol            = "HTTP"
        matcher             = "204"
      }
      protocol_version = "HTTP1"
      targets = {
        my_ec2 = {
          target_id = aws_instance.webserver[0].id
          port      = 80
        },
        my_ec2_again = {
          target_id = aws_instance.webserver[0].id
          port      = 80
        }
      }
    }
  ]

  lambda_function_association {
    event_type   = "viewer-request"
    lambda_arn   = module.basic_auth.lambda_arn
    include_body = false
  }
}



module "basic_auth" {
  source = "github.com/builtinnya/aws-lambda-edge-basic-auth-terraform/module"

  basic_auth_credentials = {
    user     = "username"
    password = "password"
  }

  # All Lambda@Edge functions must be put on us-east-1.
  # If the parent module provider region is not us-east-1, you have to
  # define and pass us-east-1 provider explicitly.
  # See https://www.terraform.io/docs/modules/usage.html#passing-providers-explicitly for detail.
  #
  providers = {
    aws.region = aws.use1
  }
}

provider "aws" {
  alias  = "use1"
  region = "us-east-1"
}
