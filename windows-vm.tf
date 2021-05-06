########################
#     Resource map     #
########################
# - main resource group
# - random names generator
# - key vault for main virtual machine credentials
# - virtual network for application resource workload
#  - backend subnet for mssql servers
#  - fronent subnet for ui web apps
# - virtual network interface for virtual machine
# - virtual machine

########################
#       Provider       #
########################
provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}

########################
#       Resource       #
########################

# Random names generator
resource "random_pet" "prefix" {}

# Application resoource group for main workload
resource "azurerm_resource_group" "main" {
  name     = "${random_pet.prefix.id}-rg"
  location = "West US 2"

  tags = {
    environment = "Demo"
  }
}

# Random password generator
resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

# Key Vault for storing adminuser password for Virtual Machine
module "WindowsVmKeyVault" {
  source = "./modules/key-vault"

  existingResourceGroupName = azurerm_resource_group.main.name
  adminuserPassword = random_password.password.result
}

# Virtual network
resource "azurerm_virtual_network" "main" {
  name                = "main-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

# Subnet dedicated for backend
resource "azurerm_subnet" "backend" {
  name                 = "backend"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Subnet dedicated for frontend
resource "azurerm_subnet" "frontend" {
  name                 = "frontend"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.5.0/24"]
}

# Network interface for Virtual Machine
resource "azurerm_network_interface" "internal" {
  name                = "internal-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.backend.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Virtual Machine
resource "azurerm_windows_virtual_machine" "main" {
  name                = "Win2016DTC"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  admin_password      = random_password.password.result
  network_interface_ids = [
    azurerm_network_interface.internal.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}