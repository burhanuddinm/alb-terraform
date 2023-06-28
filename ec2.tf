data "aws_ami" "amzn2" {
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*"] # Specify the pattern for Amazon Linux 2 AMI names here
  }
  filter {
    name   = "owner-alias"
    values = ["amazon"] # Specify the owner alias of Amazon Linux 2 AMIs here
  }
}

variable "aws_access_key" {
  description = "AWS access key"
}

variable "aws_secret_key" {
  description = "AWS secret key"
}

resource "aws_instance" "example" {
  count         = 2
  ami           = data.aws_ami.amzn2.id
  instance_type = var.instance_type
  tags = {
    Name = "example-instance-${count.index + 1}" # Specify the name tag for your instances
  }
  key_name  = var.keypair
  user_data = <<-EOF
    #!/bin/bash
    yum update -y           # Update the system packages
    yum install -y httpd    # Install Apache HTTP server
    systemctl start httpd   # Start the HTTP server
    systemctl enable httpd  # Enable the HTTP server to start on boot
  EOF
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet" "default" {
  vpc_id = data.aws_vpc.default.id
  filter {
    name   = "availability-zone"
    values = ["us-east-1"]  # Replace with your desired availability zone
  }
}

data "aws_security_group" "default" {
  vpc_id = data.aws_vpc.default.id
}

resource "aws_lb" "example" {
  name               = "example-alb"
  load_balancer_type = "application"
  subnets            = [data.aws_subnet.default.id]
  security_groups    = [data.aws_security_group.default.id]
  tags               = var.tags
}

resource "aws_lb_target_group" "example" {
  name         = "example-target-group"
  port         = 80
  protocol     = "HTTP"
  vpc_id       = data.aws_vpc.default.id
  health_check {
    path                = "/"
    port                = 80
    protocol            = "HTTP"
    interval            = 5
    timeout             = 2
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
  tags         = var.tags
}

resource "aws_lb_listener" "example" {
  load_balancer_arn = aws_lb.example.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.example.arn
  }
}

resource "aws_lb_target_group_attachment" "example" {
  count            = 2    # Specify the number of instances to attach
  target_group_arn = aws_lb_target_group.example.arn
  target_id        = aws_instance.example[count.index].id
  port             = 80
}
