terraform {
  required_version = ">= 0.12, < 0.13"
}

provider "aws" {
  region = var.aws_region

  # Allow any 2.x version of the AWS provider
  version = "~> 2.0"
}

terraform {
  backend "s3" {
    bucket         = "<YOUR S3 BUCKET>"
    key            = "<SOME PATH>/terraform.tfstate"
    region         = var.aws_region
    dynamodb_table = "<YOUR DYNAMODB TABLE>"
    encrypt        = true
  }
}

module "network" {
  source = "../modules/network"

  vpc_cidr_block     = var.vpc_cidr_block
  environment        = var.environment
  public_cidr_block  = var.public_cidr_block
  private_cidr_block = var.private_cidr_block
  dns_name           = var.dns_name
  domain_name        = var.domain_name
}

module "backoffice" {
  source = "../modules/backoffice"

  instance_count = var.backoffice_instance_count
  ami            = var.ami
  instance_type  = var.backoffice_instance_type
  domain_name    = var.domain_name
}

module "bastion-host" {
  source = "../modules/bastion-host"

  instance_count = var.bastion_host_instance_count
  ami            = var.ami
  instance_type  = var.bastion_host_instance_type
  domain_name    = var.domain_name
}

module "distribution" {
  source = "../modules/distribution"

  instance_count = var.distribution_instance_count
  ami            = var.ami
  instance_type  = var.distribution_instance_type
  domain_name    = var.domain_name
}

module "engines" {
  source = "../modules/engines"

  instance_count = var.engines_instance_count
  ami            = var.ami
  instance_type  = var.engines_instance_type
  domain_name    = var.domain_name
}

module "hazelcast" {
  source = "../modules/hazelcast"

  instance_count = var.hazelcast_instance_count
  ami            = var.ami
  instance_type  = var.hazelcast_instance_type
  domain_name    = var.domain_name
}

module "jenkins" {
  source = "../modules/jenkins"

  instance_count = var.jenkins_instance_count
  ami            = var.ami
  instance_type  = var.jenkins_instance_type
  domain_name    = var.domain_name
}

module "mongodb" {
  source = "../modules/mongodb"

  instance_count = var.mongodb_instance_count
  ami            = var.ami
  instance_type  = var.mongodb_instance_type
  domain_name    = var.domain_name
}

module "mysqldb" {
  source = "../modules/mysqldb"

  instance_count = var.mysqldb_instance_count
  ami            = var.ami
  instance_type  = var.mysqldb_instance_type
  domain_name    = var.domain_name
}

module "platform" {
  source = "../modules/platform"

  instance_count = var.platform_instance_count
  ami            = var.ami
  instance_type  = var.platform_instance_type
  domain_name    = var.domain_name
}

module "proxy01" {
  source = "../modules/proxy01"

  instance_count = var.proxy01_instance_count
  ami            = var.ami
  instance_type  = var.proxy01_instance_type
  domain_name    = var.domain_name
}

module "proxy02" {
  source = "../modules/proxy02"

  instance_count = var.proxy02_instance_count
  ami            = var.ami
  instance_type  = var.proxy02_instance_type
  domain_name    = var.domain_name
}

module "wrapper" {
  source = "../modules/wrapper"

  instance_count = var.wrapper_instance_count
  ami            = var.ami
  instance_type  = var.wrapper_instance_type
  domain_name    = var.domain_name
}

module "zabbix" {
  source = "../modules/zabbix"

  instance_count = var.zabbix_instance_count
  ami            = var.ami
  instance_type  = var.zabbix_instance_type
  domain_name    = var.domain_name
}
