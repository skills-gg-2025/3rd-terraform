# S3 Bucket Policy for ALB Access Logs
resource "aws_s3_bucket_policy" "alb_logs_policy" {
  bucket = aws_s3_bucket.apdev_s3_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::600734575887:root"
        }
        Action = "s3:PutObject"
        Resource = "${aws_s3_bucket.apdev_s3_bucket.arn}/alb/*"
      }
    ]
  })
}

# Security Group for ALB
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Security group for Application Load Balancers"
  vpc_id      = aws_vpc.apdev_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
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
    Name = "alb-sg"
  }
}

# ALB for User
resource "aws_lb" "user" {
  name               = "user"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.apdev_public_subnet_a.id, aws_subnet.apdev_public_subnet_b.id]

  access_logs {
    bucket  = aws_s3_bucket.apdev_s3_bucket.bucket
    prefix  = "alb"
    enabled = true
  }

  tags = {
    Name = "user"
  }
}

# ALB for Stress
resource "aws_lb" "stress" {
  name               = "stress"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.apdev_public_subnet_a.id, aws_subnet.apdev_public_subnet_b.id]

  access_logs {
    bucket  = aws_s3_bucket.apdev_s3_bucket.bucket
    prefix  = "alb"
    enabled = true
  }

  tags = {
    Name = "stress"
  }
}

# ALB for Product
resource "aws_lb" "product" {
  name               = "product"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.apdev_public_subnet_a.id, aws_subnet.apdev_public_subnet_b.id]

  access_logs {
    bucket  = aws_s3_bucket.apdev_s3_bucket.bucket
    prefix  = "alb"
    enabled = true
  }

  tags = {
    Name = "product"
  }
}