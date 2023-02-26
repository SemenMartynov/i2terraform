# -------------------------------------------------------------------
#
# Provision Highly Available Web
#
# -------------------------------------------------------------------

provider "aws" {
  region = "eu-north-1" # Stockholm
}

# -------------------------------------------------------------------
# - Security Group for Web Server                                   -
# -------------------------------------------------------------------

resource "aws_security_group" "webserver" {
  name        = "WebServer Security Group"
  description = "SecurityGroup for the High Avalability WebServers"

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

# -------------------------------------------------------------------
# - Launching Configuration with Auto AMI Lookup                    -
# -------------------------------------------------------------------

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

resource "aws_launch_configuration" "web" {
  name_prefix     = "WebServer-LC-"
  image_id        = data.aws_ami.latest_amazon_linux.id
  instance_type   = "t3.micro" # 2vCPU, 1G
  security_groups = [aws_security_group.webserver.id]
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
}

# -------------------------------------------------------------------
# - Auto Scaling Group (with 2 Availability Zones)                  -
# -------------------------------------------------------------------

data "aws_availability_zones" "available" {}

resource "aws_default_subnet" "default_azone1" {
  availability_zone = data.aws_availability_zones.available.names[0]
}

resource "aws_default_subnet" "default_azone2" {
  availability_zone = data.aws_availability_zones.available.names[1]
}

resource "aws_autoscaling_group" "web" {
  name                 = "ASG-${aws_launch_configuration.web.name}"
  launch_configuration = aws_launch_configuration.web.name
  min_size             = 2
  max_size             = 2
  min_elb_capacity     = 2
  vpc_zone_identifier  = [aws_default_subnet.default_azone1.id, aws_default_subnet.default_azone2.id]
  #health_check_type = "EC2"
  health_check_type = "ELB"
  load_balancers    = [aws_elb.web.name]

  lifecycle {
    //prevent_destroy = true
    //ignore_changes = ["ami", "user_data"]
    create_before_destroy = true
  }

  dynamic "tag" {
    for_each = {
      Name  = "WebServer in ASG"
      Owner = "Semen Martynov"
    }
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

# -------------------------------------------------------------------
# - Load Balancer (with 2 Availability Zones)                       -
# -------------------------------------------------------------------

resource "aws_elb" "web" {
  name               = "WebServer-ELB"
  availability_zones = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1]]
  security_groups    = [aws_security_group.webserver.id]
  listener {
    lb_port           = 80
    lb_protocol       = "http"
    instance_port     = 80
    instance_protocol = "http"
  }
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "http:80/"
    interval            = 10
  }
  tags = {
    Name  = "WebServer LB"
    Owner = "Semen Martynov"
  }
}

/*
resource "aws_eip" "webserver_static_ip" {
  instance = aws_instance.my_webserver.id

  tags = {
    Name  = "Elastic IP address for the Web Server"
    Owner = "Semen Martynov"
  }
}
*/
