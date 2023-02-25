# ------------------------------
# Simple web-service
# ------------------------------

provider "aws" {
  #  access_key = "AKIA3BI6WTWR7ZDWH64O"
  #  secret_key = "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"
  region = "eu-north-1" # Stockholm
}

resource "aws_eip" "webserver_static_ip" {
  instance = aws_instance.my_webserver.id

  tags = {
    Name  = "Elastic IP address for the Web Server"
    Owner = "Semen Martynov"
  }
}

data "aws_ami" "latest_amazon_linux" {
  most_recent = true
  owners = [ "amazon" ]

  filter {
    name = "name"
    values = ["amzn2-ami-*-gp2"]
  }

  filter {
    name = "root-device-type"
    values = [ "ebs" ]
  }

  filter {
    name = "virtualization-type"
    values = [ "hvm" ]
  }

  filter {
    name = "architecture"
    values = [ "x86_64" ]
  }
}

resource "aws_instance" "my_webserver" {
  ami                    = data.aws_ami.latest_amazon_linux.id
  instance_type          = "t3.micro"              # 2vCPU, 1G
  vpc_security_group_ids = [aws_security_group.my_webserver.id]
  user_data = templatefile("userdata.sh.tpl", {
    this_month = "February",
    next_month = "March",
    week_days  = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
  })

  lifecycle {
    //prevent_destroy = true
    //ignore_changes = ["ami", "user_data"]
    create_before_destroy = true
  }

  tags = {
    Name  = "Web Server build by Terraform"
    Owner = "Semen Martynov"
  }
}

resource "aws_security_group" "my_webserver" {
  name        = "WebServer Security Group"
  description = "My First SecurityGroup"

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

  tags = {
    Name  = "Web Server SecurityGroup"
    Owner = "Semen Martynov"
  }
}
