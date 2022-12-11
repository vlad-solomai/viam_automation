# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# Provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

variable "instance_count" {
  description = "Cound of instances"
  type        = string
}

variable "environment" {
  description = "Enter environment name"
  type        = string
}

variable "location" {
  description = "Enter location name"
  type        = string
}
