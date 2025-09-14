# ECS Instance Type Variable
variable "ecs_instance_type" {
  description = "Instance type for ECS instances"
  type        = string
}

# DB Instance Type Variable
variable "db_instance_type" {
  description = "Instance class for RDS database"
  type        = string
}

# DB Storage Type Variable
variable "db_storage_type" {
  description = "Storage type for RDS database"
  type        = string
}

