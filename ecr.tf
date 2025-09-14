# ECR Repository for product
resource "aws_ecr_repository" "product" {
  name                 = "product"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }

  tags = {
    Name = "product"
  }
}

# ECR Repository for stress
resource "aws_ecr_repository" "stress" {
  name                 = "stress"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }

  tags = {
    Name = "stress"
  }
}

# ECR Repository for user
resource "aws_ecr_repository" "user" {
  name                 = "user"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }

  tags = {
    Name = "user"
  }
}