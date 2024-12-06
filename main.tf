provider "azurerm" {
  features {}
}

# Define variables
variable "vm_name" {
  description = "The name of the virtual machine."
  type        = string
  default     = "myVM"
}

variable "region" {
  description = "Azure region where the VM will be created."
  type        = string
  default     = "East US"
}

variable "size" {
  description = "Size of the VM (CPU, RAM)."
  type        = string
  default     = "Standard_DS1_v2"
}

variable "admin_username" {
  description = "The username for the admin account on the VM."
  type        = string
  default     = "azureuser"
}

variable "admin_password" {
  description = "The password for the admin account on the VM."
  type        = string
  sensitive   = true
}

variable "disk_size_gb" {
  description = "Size of the OS disk in GB."
  type        = number
  default     = 30
}

# Create Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "${var.vm_name}-rg"
  location = var.region
}

# Create Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.vm_name}-vnet"
  location            = var.region
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

# Create Subnet
resource "azurerm_subnet" "subnet" {
  name                 = "${var.vm_name}-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create Public IP
resource "azurerm_public_ip" "public_ip" {
  name                = "${var.vm_name}-public-ip"
  location            = var.region
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

# Create Network Interface
resource "azurerm_network_interface" "nic" {
  name                  = "${var.vm_name}-nic"
  location              = var.region
  resource_group_name   = azurerm_resource_group.rg.name
  subnet_id             = azurerm_subnet.subnet.id
  private_ip_address_allocation = "Dynamic"

  ip_configuration {
    name                          = "internal"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

# Create Virtual Machine
resource "azurerm_linux_virtual_machine" "vm" {
  name                = var.vm_name
  location            = var.region
  resource_group_name = azurerm_resource_group.rg.name
  size                = var.size
  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  computer_name       = var.vm_name
  disable_password_authentication = false

  os_disk {
    name              = "${var.vm_name}-os-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    disk_size_gb      = var.disk_size_gb
    managed           = true
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "20.04-LTS"
    version   = "latest"
  }

  tags = {
    environment = "Production"
  }
}

# Output VM public IP address
output "public_ip" {
  value = azurerm_public_ip.public_ip.ip_address
}