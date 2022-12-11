terraform {
  required_version = ">= 0.12, < 0.13"
}

# Create network interface for mongodb host.
resource "azurerm_network_interface" "mongodb_${var.environment}_nic" {
  name                = "mongodb_${var.environment}_NIC"
  location            = azurerm_resource_group.${var.environment}_group.location
  resource_group_name = azurerm_resource_group.${var.environment}_group.name

  ip_configuration {
    name                          = "mongodb_${var.environment}_NicConfiguration"
    subnet_id                     = azurerm_subnet.${var.environment}_private_subnet.id
    private_ip_address_allocation = "dynamic"
  }

  tags = {
    environment = "${var.environment} ${var.location}"
  }
}

# Connect the security group to the mongodb network interface
resource "azurerm_network_interface_security_group_association" "mongodb_nic_sg_acc" {
    network_interface_id      = azurerm_network_interface.mongodb_${var.environment}_nic.id
    network_security_group_id = azurerm_network_security_group.${var.environment}_private_sg.id
}

# Generate random text for a unique storage account name
resource "random_id" "mongodb_${var.environment}_randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = azurerm_resource_group.${var.environment}_group.name
    }

    byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "mongodb_${var.environment}_storageaccount" {
    name                        = "diag${random_id.mongodb_${var.environment}_randomId.hex}"
    resource_group_name         = azurerm_resource_group.${var.environment}_group.name
    location                    = azurerm_resource_group.${var.environment}_group.location
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags = {
        environment = "${var.environment} ${var.location}"
    }
}

# Create mongodb virtual machine
resource "azurerm_linux_virtual_machine" "mongodb_${var.environment}" {
    name                  = "mongodb_${var.environment}"
    location              = azurerm_resource_group.${var.environment}_group.location
    resource_group_name   = azurerm_resource_group.${var.environment}_group.name
    network_interface_ids = [azurerm_network_interface.mongodb_${var.environment}_nic.id]
    size                  = "Standard_D8_v4"

    os_disk {
        name                 = "mongodb_${var.environment}_OsDisk"
        caching              = "ReadWrite"
        storage_account_type = "Standard_LRS"
        disk_size_gb         = "150"
    }

    source_image_reference {
        publisher = "OpenLogic"
        offer     = "CentOS"
        sku       = "7_9"
        version   = "latest"
    }

    computer_name  = "mongodb_${var.environment}"
    admin_username = "jenkins"
    disable_password_authentication = true

    admin_ssh_key {
        username       = "jenkins"
        public_key = file("id_rsa_jenkins.pub")
    }

    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.mongodb_${var.environment}_storageaccount.primary_blob_endpoint
    }

    tags = {
        environment = "${var.environment} ${var.location}"
    }
}
