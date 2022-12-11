# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# Provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

variable "vpc_cidr_block" {
  description = "The cidr_block for VPC"
  type        = string
}

variable "public_cidr_block" {
  description = "The cidr_block for public subnet"
  type        = string
}

variable "private_cidr_block" {
  description = "The cidr_block for private subnet"
  type        = string
}

variable "environment" {
  description = "The name of environment"
  type        = string
}

variable "dns_name" {
  description = "The name for DNS"
  type        = string
}
variable "location" {
  description = "Region name"
  type        = string
}
