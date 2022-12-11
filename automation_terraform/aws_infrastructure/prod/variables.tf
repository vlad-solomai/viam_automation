variable "aws_region" {
  default = "eu-west-2"
}

variable "ami" {
  description = "ami for instances"
  type        = map

  default     = {
    "linux_ami"   = "ami-005b5c720e7b986d6"
    "windows_ami" = "ami-0a262e3ac12949132"
  }
}

variable "instance_count" {
  type = map

  default = {
    "backoffice_instance_count"    = "1"
    "bastion_host_instance_count"  = "1"
    "distribution_instance_count"  = "4"
    "hazelcast_instance_count"     = "2"
    "jenkins_instance_count"       = "1"
    "mongodb_instance_count"       = "3"
    "mysqldb_instance_count"       = "2"
    "platform_instance_count"      = "2"
    "web_proxy_instance_count"     = "1"
    "service_proxy_instance_count" = "1"
    "wrapper_instance_count"       = "2"
    "zabbix_instance_count"        = "1"
    "engines_instance_count"       = "2"
  }
}

variable "instance_type" {
  type = map

  default = {
    "backoffice_instance_type"    = "t2.medium"
    "bastion_host_instance_type"  = "t2.micro"
    "distribution_instance_type"  = "m5.large"
    "hazelcast_instance_type"     = "t2.medium"
    "jenkins_instance_type"       = "t2.medium"
    "mongodb_instance_type"       = "m5.2xlarge"
    "mysqldb_instance_type"       = "m5.4xlarge"
    "platform_instance_type"      = "m5.large"
    "web_proxy_instance_type"     = "m5.large"
    "service_proxy_instance_type" = "m5.large"
    "wrapper_instance_type"       = "m5.large"
    "zabbix_instance_type"        = "t2.medium"
    "engines_instance_type"       = "m5.xlarge"
  }
}

variable "vpc_cidr_block" {
  default = "10.32.0.0/16"
}

variable "environment" {
  default = "prod"
}

variable "public_cidr_block" {
  default = "10.32.0.0/24"
}

variable "private_cidr_block" {
  default = "10.32.1.0/24"
}

variable "dns_name" {
  default = "prod.com"
}

variable "domain_name" {
  default = "prod.com"
}
