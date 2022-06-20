# Pull ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Get private subnets
data "aws_vpc" "vpc" {
  tags = {
    Environment = terraform.workspace
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }
  tags = {
    SubnetType = "private"
  }
}

# Create security group
resource "aws_security_group" "sg" {
  name        = "${terraform.workspace}-web-sg"
  description = "Allow ssh http inbound traffic"
  vpc_id      = data.aws_vpc.vpc.id

  ingress {
    description      = "SSH from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "HTTP from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = local.tags
}

# Create EC2 mock web server using use data.
resource "aws_instance" "ec2_web" {
  count           = var.intance_count
  ami             = data.aws_ami.ubuntu.id
  instance_type   = var.instance_type
  key_name        = var.instance_key
  subnet_id       = element(data.aws_subnets.private.ids, 0)
  vpc_security_group_ids = [aws_security_group.sg.id]

  user_data = <<-EOF
  #!/bin/bash
  echo "*** Installing apache2"
  sudo apt update -y
  sudo apt install apache2 -y
  echo "*** Completed Installing apache2"
  EOF

  tags = merge(
    local.tags,
    {
      "Name" = "${terraform.workspace}-web-instance-${count.index}",
    },
  )

  volume_tags = {
    Name = "${terraform.workspace}-web-instance-${count.index}"
  }
}


# ALB Security group
resource "aws_security_group" "alb_allow_all_sg" {
  count       = var.intance_count >= 2 ? 1 : 0
  name        = "${terraform.workspace}-web-instance-alb-sg"
  description = "Allow all traffic"
  vpc_id      = data.aws_vpc.vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

# Target Group Creation
resource "aws_alb_target_group" "tg" {
  count       = var.intance_count >= 2 ? 1 : 0
  name        = "${terraform.workspace}-web-instance-alb-tg"
  port        = 80
  target_type = "instance"
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.vpc.id
}

# Create ALB if there are two or more instances
resource "aws_lb" "web_alb" {
  count              = var.intance_count >= 2 ? 1 : 0
  name               = "${terraform.workspace}-web-instance-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_allow_all_sg[0].id]
  subnets            = data.aws_subnets.public.ids

  enable_deletion_protection = false

  tags = local.tags
}

# Target Group Attachment with Instance
resource "aws_alb_target_group_attachment" "tgattachment" {
  count            = var.intance_count >= 2 ? length(aws_instance.ec2_web[*].id) : 0
  target_group_arn = aws_alb_target_group.tg[0].arn
  target_id        = element(aws_instance.ec2_web[*].id, count.index)
}

##Add Listener
resource "aws_alb_listener" "listener" {
  load_balancer_arn = aws_lb.web_alb[0].arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.tg[0].id
    type             = "forward"
  }
}

# Get public subnets
data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }
  tags = {
    SubnetType = "public"
  }
}
