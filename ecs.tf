# Data source for Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-ecs-hvm-*-x86_64"]
  }
}

# Security Group for ECS
resource "aws_security_group" "apdev_ecs_sg" {
  name        = "apdev-ecs-sg"
  description = "Security group for ECS instances"
  vpc_id      = aws_vpc.apdev_vpc.id

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "apdev-ecs-sg"
  }
}

# IAM Role for ECS Instance
resource "aws_iam_role" "apdev_ecs_instance_role" {
  name = "apdev-ecs-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "apdev_ecs_instance_role_policy" {
  role       = aws_iam_role.apdev_ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "apdev_ecs_instance_profile" {
  name = "apdev-ecs-instance-profile"
  role = aws_iam_role.apdev_ecs_instance_role.name
}

# IAM Role for Product Task
resource "aws_iam_role" "product_task_role" {
  name = "product-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "product_task_role_dynamodb" {
  role       = aws_iam_role.product_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

# Launch Template for ECS
resource "aws_launch_template" "apdev_ecs_launch_template" {
  name_prefix   = "apdev-ecs-"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = var.ecs_instance_type

  vpc_security_group_ids = [aws_security_group.apdev_ecs_sg.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.apdev_ecs_instance_profile.name
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              echo ECS_CLUSTER=${aws_ecs_cluster.apdev_ecs_cluster.name} >> /etc/ecs/ecs.config
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "apdev-ecs-instance"
    }
  }
}

# Auto Scaling Group for ECS
resource "aws_autoscaling_group" "apdev_ecs_asg" {
  name                = "apdev-ecs-asg"
  vpc_zone_identifier = [aws_subnet.apdev_private_subnet_a.id, aws_subnet.apdev_private_subnet_b.id]
  min_size            = 2
  max_size            = 4
  desired_capacity    = 2
  protect_from_scale_in = true

  launch_template {
    id      = aws_launch_template.apdev_ecs_launch_template.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "apdev-ecs-asg"
    propagate_at_launch = false
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = true
    propagate_at_launch = false
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "apdev_ecs_cluster" {
  name = "apdev-ecs-cluster"

  setting {
    name  = "containerInsights"
    value = "enhanced"
  }

  tags = {
    Name = "apdev-ecs-cluster"
  }
}

# ECS Capacity Provider
resource "aws_ecs_capacity_provider" "apdev_ecs_capacity_provider" {
  name = "apdev-ecs-capacity-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.apdev_ecs_asg.arn
    managed_termination_protection = "ENABLED"

    managed_scaling {
      status          = "ENABLED"
      target_capacity = 80
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "apdev_ecs_cluster_capacity_providers" {
  cluster_name = aws_ecs_cluster.apdev_ecs_cluster.name

  capacity_providers = [aws_ecs_capacity_provider.apdev_ecs_capacity_provider.name]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = aws_ecs_capacity_provider.apdev_ecs_capacity_provider.name
  }
}
