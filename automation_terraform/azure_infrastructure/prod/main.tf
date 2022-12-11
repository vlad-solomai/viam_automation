terraform {
  required_version = ">= 0.12, < 0.13"
}

provider "azurerm" {
    # The "feature" block is required for AzureRM provider 2.x. 
    # If you're using version 1.x, the "features" block is not allowed.
    version = "~>2.0"
    features {}

    subscription_id = ""
    client_id       = ""
    client_secret   = ""
    tenant_id       = ""

}

terraform {
  backend "s3" {
    bucket         = "<YOUR S3 BUCKET>"
    key            = "<SOME PATH>/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "<YOUR DYNAMODB TABLE>"
    encrypt        = true
  }
}

module "network" {
  source = "../modules/network"

  vpc_cidr_block     = var.vpc_cidr_block
  environment        = var.environment_primary
  public_cidr_block  = var.public_cidr_block
  private_cidr_block = var.private_cidr_block
  dns_name           = var.dns_name_primary
  domain_name        = var.location_primary
}


module "network" {
  source = "../modules/network"

  vpc_cidr_block     = var.vpc_cidr_block
  environment        = var.environment_secondary
  public_cidr_block  = var.public_cidr_block
  private_cidr_block = var.private_cidr_block
  dns_name           = var.dns_name_secondary
  domain_name        = var.location_secondary
}


module "backoffice" {
  source = "../modules/backoffice"

  instance_count = var.instance_count
  environment    = var.environment
  location       = var.location
}

module "bastion-host" {
  source = "../modules/bastion-host"

  instance_count = var.instance_count
  environment    = var.environment
  location       = var.location
}

module "distribution" {
  source = "../modules/distribution"

  instance_count = var.instance_count
  environment    = var.environment
  location       = var.location
}

module "engines" {
  source = "../modules/engines"

  instance_count = var.instance_count
  environment    = var.environment
  location       = var.location
}

module "hazelcast" {
  source = "../modules/hazelcast"

  instance_count = var.instance_count
  environment    = var.environment
  location       = var.location
}

module "jenkins" {
  source = "../modules/jenkins"

  instance_count = var.instance_count
  environment    = var.environment
  location       = var.location
}

module "mongodb" {
  source = "../modules/mongodb"

  instance_count = var.instance_count
  environment    = var.environment
  location       = var.location
}

module "mysqldb" {
  source = "../modules/mysqldb"

  instance_count = var.instance_count
  environment    = var.environment
  location       = var.location
}

module "platform" {
  source = "../modules/platform"

  instance_count = var.instance_count
  environment    = var.environment
  location       = var.location
}

module "proxy01" {
  source = "../modules/proxy01"

  instance_count = var.instance_count
  environment    = var.environment
  location       = var.location
}

module "proxy02" {
  source = "../modules/proxy02"

  instance_count = var.instance_count
  environment    = var.environment
  location       = var.location
  domain_name    = var.domain_name
}

module "wrapper" {
  source = "../modules/wrapper"

  instance_count = var.instance_count
  environment    = var.environment
  location       = var.location
}

module "zabbix" {
  source = "../modules/zabbix"

  instance_count = var.instance_count
  environment    = var.environment
  location       = var.location
}
