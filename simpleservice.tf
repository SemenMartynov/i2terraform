# ------------------------------
# Simple web-service
# ------------------------------

provider "aws" {
#  access_key = "AKIA3BI6WTWR7ZDWH64O"
#  secret_key = "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"
  region     = "eu-north-1" # Stockholm
}

resource "aws_instance" "my_webserver" {
  ami                    = "ami-0bb935e4614c12d86" # Amazon Linux 2 Kernel 5.10
  instance_type          = "t3.micro"              # 2vCPU, 1G
  vpc_security_group_ids = [aws_security_group.my_webserver.id]
  user_data              = templatefile("userdata.sh.tpl", {
    this_month = "February",
    next_month = "March",
    week_days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
  })

  tags = {
    Name  = "Web Server build by Terraform"
    Owner = "Semen Martynov"
  }
}

resource "aws_security_group" "my_webserver" {
  name        = "WebServer Security Group"
  description = "My First SecurityGroup"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Recieve http request"
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
