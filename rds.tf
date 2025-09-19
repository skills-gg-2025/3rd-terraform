# DB Subnet Group
resource "aws_db_subnet_group" "apdev_db_subnet_group" {
  name       = "apdev-db-subnet-group"
  subnet_ids = [aws_subnet.apdev_private_subnet_a.id, aws_subnet.apdev_private_subnet_b.id]

  tags = {
    Name = "apdev-db-subnet-group"
  }
}

# DB Parameter Group
resource "aws_db_parameter_group" "apdev_db_parameter_group" {
  name   = "apdev-db-parameter-group"
  family = "mysql8.0"

  parameter {
    name  = "max_connections"
    value = "100000"
  }

  parameter {
    name  = "max_user_connections"
    value = "100000"
  }

  tags = {
    Name = "apdev-db-parameter-group"
  }
}

# Security Group for RDS
resource "aws_security_group" "apdev_rds_sg" {
  name        = "apdev-rds-sg"
  description = "Security group for RDS instance"
  vpc_id      = aws_vpc.apdev_vpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
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
    Name = "apdev-rds-sg"
  }
}

# RDS Instance
resource "aws_db_instance" "apdev_rds_instance" {
  identifier     = "apdev-rds-instance"
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = var.db_instance_type
  
  allocated_storage     = 100
  max_allocated_storage = 200
  storage_type          = var.db_storage_type
  storage_encrypted     = true
  
  db_name  = "dev"
  username = "admin"
  password = "Skill53##"
  
  multi_az               = true
  db_subnet_group_name   = aws_db_subnet_group.apdev_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.apdev_rds_sg.id]
  parameter_group_name   = aws_db_parameter_group.apdev_db_parameter_group.name
  
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  
  skip_final_snapshot = true
  deletion_protection = false
  
  # Enable DB logs
  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]

  tags = {
    Name = "apdev-rds-instance"
  }
}
