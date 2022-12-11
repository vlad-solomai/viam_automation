terraform {
  required_version = ">= 0.12, < 0.13"
}

# Create a public IP address for bastion host VM in public subnet.
resource "azurerm_public_ip" "bastion_public_ip" {
  name                = "Toronto-bastion-ip"
  resource_group_name = azurerm_resource_group.${var.environment}_group.name
  location            = azurerm_resource_group.${var.environment}_group.location
  allocation_method   = "Static"

  tags = {
    environment = "${var.environment} ${var.location}"
  }
}

# Create network interface for bastion host.
resource "azurerm_network_interface" "bastionnic" {
    name                      = "BastionNIC"
    location                  = azurerm_resource_group.${var.environment}_group.location
    resource_group_name       = azurerm_resource_group.${var.environment}_group.name

    ip_configuration {
        name                          = "BastionNicConfiguration"
        subnet_id                     = azurerm_subnet.${var.environment}_public_subnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.bastion_public_ip.id
    }

    tags = {
        environment = "${var.environment} ${var.location}"
    }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "bastion_nic_sg_acc" {
    network_interface_id      = azurerm_network_interface.bastionnic.id
    network_security_group_id = azurerm_network_security_group.${var.environment}_public_sg.id
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = azurerm_resource_group.${var.environment}_group.name
    }

    byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "bastionstorageaccount" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = azurerm_resource_group.${var.environment}_group.name
    location                    = azurerm_resource_group.${var.environment}_group.location
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags = {
        environment = "${var.environment} ${var.location}"
    }
}

# Create Bastion virtual machine
resource "azurerm_linux_virtual_machine" "bastionvm" {
    name                  = "bastion_${var.environment}"
    location              = azurerm_resource_group.${var.environment}_group.location
    resource_group_name   = azurerm_resource_group.${var.environment}_group.name
    network_interface_ids = [azurerm_network_interface.bastionnic.id]
    size                  = "Standard_B1s"

    os_disk {
        name              = "BastionOsDisk"
        caching           = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }

    source_image_reference {
        publisher = "OpenLogic"
        offer     = "CentOS"
        sku       = "7_9"
        version   = "latest"
    }

    computer_name  = "bastion_${var.environment}"
    admin_username = "jenkins"
    disable_password_authentication = true

    admin_ssh_key {
        username       = "jenkins"
        public_key     = file("id_rsa.pub")
    }

    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.bastionstorageaccount.primary_blob_endpoint
    }

    tags = {
        environment = "${var.environment} ${var.location}"
    }
}
