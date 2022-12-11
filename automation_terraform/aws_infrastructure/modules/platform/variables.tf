# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# Provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

variable "instance_count" {
  description = "Cound of instances"
  type        = string
}

variable "ami" {
  description = "The ami of instance"
  type        = string
}

variable "instance_type" {
  description = "Enter instance type"
  type        = string
}

variable "domain_name" {
  description = "Enter domain name for route53"
  type        = string
}
