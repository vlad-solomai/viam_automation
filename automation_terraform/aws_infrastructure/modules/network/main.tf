terraform {
  required_version = ">= 0.12, < 0.13"
}
# ----------------------------------------------VPC configuration--------------------------------------------------------#
# Create a VPC
resource "aws_vpc" "working_vpc" {
  cidr_block = var.vpc_cidr_block
  enable_dns_support = true
  enable_dns_hostnames = true
  enable_classiclink_dns_support = true

  tags = {
    Name    = "${var.environment} VPC"
  }
}

# Create the Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.working_vpc.id
  cidr_block              = var.public_cidr_block
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.environment} Public Subnet"
  }
}

# Create the Private Subnet
resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.working_vpc.id
  cidr_block              = var.private_cidr_block
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.environment} Private Subnet"
  }
}

# Create the Internet Gateway
resource "aws_internet_gateway" "vpc_igw" {
  vpc_id = aws_vpc.working_vpc.id

  tags = {
    Name = "${var.environment} VPC Internet Gateway"
  }
}

# Create the NAT Gateway
resource "aws_eip" "nat_gw_ip" {
  vpc = true
}

resource "aws_nat_gateway" "vpc_nat_gw" {
  allocation_id = aws_eip.nat_gw_ip.id
  subnet_id     = aws_subnet.public_subnet.id

  tags = {
    Name = "${var.environment} VPC NAT Gateway"
  }
}

# Create the Public Route Table
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.working_vpc.id

  tags = {
    Name = "${var.environment} VPC Public subnet Route Table"
  }
}

# Create the Internet Access Route
resource "aws_route" "public_subnet_internet_access" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.vpc_igw.id
}

# Associate the Route Table with the Public Subnet
resource "aws_route_table_association" "vpc_public_subnet_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

# Create the Private Route Table
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.working_vpc.id

  tags = {
    Name = "${var.environment} VPC Private subnet Route Table"
  }
}

# Create the Internet Access Route
resource "aws_route" "private_subnet_internet_access" {
  route_table_id         = aws_route_table.private_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.vpc_nat_gw.id
}

# Associate the Route Table with the Private Subnet
resource "aws_route_table_association" "vpc_private_subnet_association" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_route_table.id
}

# ----------------------------------------------DNS and DHCP configuration-----------------------------------------------#
# Create DNS Private Zone
resource "aws_route53_zone" "dns_zone" {
  name = "${var.dns_name}"

  vpc {
    vpc_id = aws_vpc.working_vpc.id
  }
}

# Create and associate DHCP option set
resource "aws_vpc_dhcp_options" "dhcp_set" {
  domain_name          = "${var.domain_name}"
  domain_name_servers  = ["AmazonProvidedDNS"]

  tags = {
    Name = "${var.environment} DHCP options"
  }
}

resource "aws_vpc_dhcp_options_association" "dhcp_association" {
  vpc_id          = aws_vpc.working_vpc.id
  dhcp_options_id = aws_vpc_dhcp_options.dhcp_set.id
}

# ----------------------------------------------Security Group configuration-----------------------------------------------#
# Create Public Subnet SG
resource "aws_security_group" "public_subnet_sg" {
  vpc_id       = aws_vpc.working_vpc.id
  name         = "${var.environment} Public Subnet SG"
  description  = "${var.environment} Public Subnet SG"

  # allow ingress of port 22
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # allow ingress of port 22022
  ingress {
    from_port   = 22022
    to_port     = 22022
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # allow ingress of all subnets
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${var.vpc_cidr_block}"]
  }

  # allow egress of all ports
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment} Public Subnet SG"
    Description = "${var.environment} Public Subnet SG"
  }
}

# Create HTTPS Public Subnet SG
resource "aws_security_group" "public_subnet_https_sg" {
  vpc_id       = aws_vpc.working_vpc.id
  name         = "${var.environment} HTTPS SG"
  description  = "${var.environment} HTTPS SG"

  # allow ingress of port 443
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.environment} Public Subnet HTTPS SG"
    Description = "${var.environment} Public Subnet HTTPS SG"
  }
}

# Create SSH Public Subnet SG
resource "aws_security_group" "public_subnet_ssh_sg" {
  vpc_id       = aws_vpc.working_vpc.id
  name         = "${var.environment} SSH SG"
  description  = "${var.environment} SSH SG"

  # allow ingress of port 22
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
    # allow ingress of port 22022
  ingress {
    from_port   = 22022
    to_port     = 22022
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment} Public Subnet SSH SG"
    Description = "${var.environment} Public Subnet SSH SG"
  }
}

# Create RDP Public Subnet SG
resource "aws_security_group" "public_subnet_rdp_sg" {
  vpc_id       = aws_vpc.working_vpc.id
  name         = "${var.environment} RDP SG"
  description  = "${var.environment} RDP SG"

  # allow ingress of port 3389
  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["80.80.80.80/32"]
  }

  tags = {
    Name = "${var.environment} Public Subnet RDP SG"
    Description = "${var.environment} Public Subnet RDP SG"
  }
}

# Create Private Subnet SG
resource "aws_security_group" "private_subnet_sg" {
  vpc_id       = aws_vpc.working_vpc.id
  name         = "${var.environment} Private Subnet SG"
  description  = "${var.environment} Private Subnet SG"

  # allow ingress of all private subnets
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${var.vpc_cidr_block}"]
  }

  # allow egress of all ports
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment} Private Subnet SG"
    Description = "${var.environment} Private Subnet SG"
  }
}
