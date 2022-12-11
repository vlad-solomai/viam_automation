terraform {
  required_version = ">= 0.12, < 0.13"
}

# Create a resource group if it doesn't exist
resource "azurerm_resource_group" "${var.environment}_group" {
    name     = "${var.environment}_group"
    location = "${var.location}"

    tags = {
        environment = "${var.environment} ${var.location}"
    }
}

# Create virtual network
resource "azurerm_virtual_network" "${var.environment}_network" {
    name                = "${var.environment}_vnet"
    address_space       = ["${var.vpc_cidr_block}"]
    location            = azurerm_resource_group.${var.environment}_group.location
    resource_group_name = azurerm_resource_group.${var.environment}_group.name

    tags = {
        environment = "${var.environment} ${var.location}"
    }
}

# Create private subnet
resource "azurerm_subnet" "${var.environment}_private_subnet" {
    name                 = "${var.environment}_private_subnet"
    resource_group_name  = azurerm_resource_group.${var.environment}_group.name
    virtual_network_name = azurerm_virtual_network.${var.environment}_network.name
    address_prefixes     = ["${var.private_cidr_block}"]
}

# Create public subnet
resource "azurerm_subnet" "${var.environment}_public_subnet" {
    name                 = "${var.environment}_public_subnet"
    resource_group_name  = azurerm_resource_group.${var.environment}_group.name
    virtual_network_name = azurerm_virtual_network.${var.environment}_network.name
    address_prefixes     = ["${var.public_cidr_block}"]
}

# Create Azure NAT Gateway
resource "azurerm_public_ip" "${var.environment}_nat_ip" {
  name                = "${var.environment}_nat_gateway_public_ip"
  location            = azurerm_resource_group.${var.environment}_group.location
  resource_group_name = azurerm_resource_group.${var.environment}_group.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1"] # azure doesn`t support in some location
}

resource "azurerm_nat_gateway" "${var.environment}_nat_gataway" {
  name                    = "${var.environment}_nat_gateway"
  location                = azurerm_resource_group.${var.environment}_group.location
  resource_group_name     = azurerm_resource_group.${var.environment}_group.name
  public_ip_address_ids   = [azurerm_public_ip.${var.environment}_nat_ip.id]
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
  zones                   = ["1"] # azure doesn`t support in some location
}

resource "azurerm_subnet_nat_gateway_association" "${var.environment}_nat_gataway" {
  subnet_id      = azurerm_subnet.${var.environment}_private_subnet.id
  nat_gateway_id = azurerm_nat_gateway.${var.environment}_nat_gataway.id
}

# Create Public Network Security Group and rule
resource "azurerm_network_security_group" "${var.environment}_public_sg" {
    name                = "${var.environment}_public_network_sg"
    location            = azurerm_resource_group.${var.environment}_group.location
    resource_group_name = azurerm_resource_group.${var.environment}_group.name

    # Allow SSH traffic
    security_rule {
        name                       = "SSH1"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22022"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
    
    security_rule {
        name                       = "SSH2"
        priority                   = 1002
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "VirtualNetwork"
        destination_address_prefix = "VirtualNetwork"
    }
    
    # Allow HTTPS traffic
        security_rule {
        name                       = "HTTPS"
        priority                   = 1003
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "*"
        destination_address_prefix = "VirtualNetwork"
    }

    # Allow RDP traffic
        security_rule {
        name                       = "RDP"
        priority                   = 1004
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "3389"
        source_address_prefix      = "80.80.80.80/32"
        destination_address_prefix = "*"
    }

        security_rule {
        name                       = "RDP_AWS_VPN"
        priority                   = 1005
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "3389"
        source_address_prefix      = "80.80.80.80/32"
        destination_address_prefix = "*"
    }

    tags = {
        environment = "${var.environment} ${var.location}"
    }
}

# Associate network security group with public subnet.
resource "azurerm_subnet_network_security_group_association" "${var.environment}_public_subnet_assoc" {
  subnet_id                 = azurerm_subnet.${var.environment}_public_subnet.id
  network_security_group_id = azurerm_network_security_group.${var.environment}_public_sg.id
}

# Create Private Network Security Group and rule
resource "azurerm_network_security_group" "${var.environment}_private_sg" {
    name                = "${var.environment}_private_network_sg"
    location            = azurerm_resource_group.${var.environment}_group.location
    resource_group_name = azurerm_resource_group.${var.environment}_group.name

    security_rule {
        name                       = "SSH1"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
    security_rule {
        name                       = "mysql-peering"
        priority                   = 1002
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "3306"
        source_address_prefix      = "VirtualNetwork"
        destination_address_prefix = "VirtualNetwork"
    }

    security_rule {
        name                       = "mongodb-peering"
        priority                   = 1003
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "27017"
        source_address_prefix      = "VirtualNetwork"
        destination_address_prefix = "VirtualNetwork"
    }

    security_rule {
        name                       = "backoffice-peering"
        priority                   = 1004
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "8080"
        source_address_prefix      = "VirtualNetwork"
        destination_address_prefix = "VirtualNetwork"
    }

    security_rule {
        name                       = "platform-peering"
        priority                   = 1005
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "8081"
        source_address_prefix      = "VirtualNetwork"
        destination_address_prefix = "VirtualNetwork"
    }

    security_rule {
        name                       = "rng-peering"
        priority                   = 1006
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "8090"
        source_address_prefix      = "VirtualNetwork"
        destination_address_prefix = "VirtualNetwork"
    }

    security_rule {
        name                       = "wrapper-peering"
        priority                   = 1007
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "5588"
        source_address_prefix      = "VirtualNetwork"
        destination_address_prefix = "VirtualNetwork"
    }

    security_rule {
        name                       = "distribution-peering"
        priority                   = 1008
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "7080"
        source_address_prefix      = "VirtualNetwork"
        destination_address_prefix = "VirtualNetwork"
    }

    security_rule {
        name                       = "gameconfig-peering"
        priority                   = 1009
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "8098"
        source_address_prefix      = "VirtualNetwork"
        destination_address_prefix = "VirtualNetwork"
    }

        security_rule {
        name                       = "zabbix-agent-passive-peering"
        priority                   = 1010
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "10050"
        source_address_prefix      = "VirtualNetwork"
        destination_address_prefix = "VirtualNetwork"
    }

        security_rule {
        name                       = "zabbix-agent-active-peering"
        priority                   = 1011
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "10051"
        source_address_prefix      = "VirtualNetwork"
        destination_address_prefix = "VirtualNetwork"
    }

    tags = {
        environment = "Env 1"
    }
}

# Associate network security group with private subnet.
resource "azurerm_subnet_network_security_group_association" "${var.environment}_private_subnet_assoc" {
  subnet_id                 = azurerm_subnet.${var.environment}_private_subnet.id
  network_security_group_id = azurerm_network_security_group.${var.environment}_private_sg.id
}

# Create DNS
resource "azurerm_private_dns_zone" "dns_zone" {
  name                = "${var.dns_name}"
  resource_group_name = azurerm_resource_group.${var.environment}_group.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "${var.environment}_dns_link" {
  name                  = "${var.environment}_dns_link"
  resource_group_name   = azurerm_resource_group.${var.environment}_group.name
  private_dns_zone_name = azurerm_private_dns_zone.dns_zone.name
  virtual_network_id    = azurerm_virtual_network.${var.environment}_network.id
  registration_enabled  = "true"
}
