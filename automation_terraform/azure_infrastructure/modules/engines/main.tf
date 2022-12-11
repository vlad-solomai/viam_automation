terraform {
  required_version = ">= 0.12, < 0.13"
}

# Create a public IP address for win_${var.environment} host VM in public subnet.
resource "azurerm_public_ip" "win_${var.environment}_public_ip" {
  name                = "Toronto-win_${var.environment}_ip"
  resource_group_name = azurerm_resource_group.${var.environment}_group.name
  location            = azurerm_resource_group.${var.environment}_group.location
  allocation_method   = "Static"

  tags = {
    environment = "${var.environment} ${var.location}"
  }
}

# Create network interface for win_${var.environment} host.
resource "azurerm_network_interface" "win_${var.environment}_nic" {
    name                      = "win_${var.environment}_NIC"
    location                  = azurerm_resource_group.${var.environment}_group.location
    resource_group_name       = azurerm_resource_group.${var.environment}_group.name

    ip_configuration {
        name                          = "win_${var.environment}_NicConfiguration"
        subnet_id                     = azurerm_subnet.${var.environment}_public_subnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.win_${var.environment}_public_ip.id
    }

    tags = {
        environment = "${var.environment} ${var.location}"
    }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "win_${var.environment}_nic_sg_acc" {
    network_interface_id      = azurerm_network_interface.win_${var.environment}_nic.id
    network_security_group_id = azurerm_network_security_group.${var.environment}_private_sg.id
}

# Create win_${var.environment} virtual machine
resource "azurerm_virtual_machine" "win_${var.environment}_vm" {
    name                  = "win_${var.environment}"
    location              = azurerm_resource_group.${var.environment}_group.location
    resource_group_name   = azurerm_resource_group.${var.environment}_group.name
    network_interface_ids = [azurerm_network_interface.win_${var.environment}_nic.id]
    vm_size               = "Standard_E2s_v3"

    storage_image_reference {
        publisher = "MicrosoftWindowsServer"
        offer     = "WindowsServer"
        sku       = "2019-Datacenter"
        version   = "latest"
    }

    storage_os_disk {
        name              = "win_${var.environment}_OsDisk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Standard_LRS"
    }

    os_profile {
        computer_name  = "win_${var.environment}"
        admin_username = "jenkins"
        admin_password = "p4"
    }

    os_profile_windows_config {
        provision_vm_agent        = true
        enable_automatic_upgrades = true
    }

    tags = {
        environment = "${var.environment} ${var.location}"
    }
}
