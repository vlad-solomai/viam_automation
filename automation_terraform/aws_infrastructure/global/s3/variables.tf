variable "bucket_name" {
  description = "The name of the S3 bucket. Must be globally unique."
  type        = string
  default     = "<OUR BUCKET NAME>"
}

variable "table_name" {
  description = "The name of the DynamoDB table. Must be unique in this AWS account."
  type        = string
  default     = "<OUR TABLE NAME>"
}

variable "aws_region" {
  description = "The name of the region"
  type        = string
  default     = "<OUR REGION NAME>"
}
