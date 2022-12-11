variable "ami" {
  type = map

  default = {
    "kub-master-ami" = "ami-0eab3a90fc693af19"
    "kub-node-ami"   = "ami-0eab3a90fc693af19"
  }
}

variable "instance_count" {
  type = map

  default = {
    "kub-master-count" = "3"
    "kub-node-count"   = "3"
  }
}

variable "instance_type" {
  type = map

  default = {
    "kub-master-instance_type"     = "t2.medium"
    "kub-node-count-instance_type" = "t2.medium"
  }
}

variable "aws_region" {
  default = "eu-west-2"
}
