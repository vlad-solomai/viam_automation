variable "location_primary" {
  default = "canadacentral"
}

variable "environment_primary" {
  default = "prod"
}

variable "dns_name_primary" {
  default = "prod.com"
}

variable "location_secondary" {
  default = "eastcentral"
}

variable "environment_secondary" {
  default = "secondary"
}

variable "dns_name_secondary" {
  default = "secondary.com"
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

variable "vpc_cidr_block" {
  default = "10.0.0.0/16"
}

variable "public_cidr_block" {
  default = "10.0.2.0/24"
}

variable "private_cidr_block" {
  default = "10.0.1.0/24"
}
