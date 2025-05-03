provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rentee_rg" {
  name     = "rentee-rg"
  location = var.location
}

resource "azurerm_virtual_network" "rentee_vnet" {
  name                = "rentee-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.rentee_rg.name
}

resource "azurerm_subnet" "rentee_subnet" {
  name                 = "rentee-subnet"
  resource_group_name  = azurerm_resource_group.rentee_rg.name
  virtual_network_name = azurerm_virtual_network.rentee_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_interface" "rentee_nic" {
  name                = "rentee-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.rentee_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.rentee_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.rentee_public_ip.id
  }
}

resource "azurerm_public_ip" "rentee_public_ip" {
  name                = "rentee-public-ip"
  location            = var.location
  resource_group_name = azurerm_resource_group.rentee_rg.name
  allocation_method   = "Static"
  sku                 = "Basic"
}

resource "azurerm_linux_virtual_machine" "rentee_vm" {
  name                  = "rentee-vm"
  resource_group_name   = azurerm_resource_group.rentee_rg.name
  location              = var.location
  size                  = "Standard_B1ms"
  admin_username        = var.admin_username
  network_interface_ids = [azurerm_network_interface.rentee_nic.id]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "22_04-lts"
    version   = "latest"
  }

  custom_data = filebase64("vm_provision/cloud-init.yaml") # For Docker install + deploy
}

output "vm_public_ip" {
  value = azurerm_public_ip.rentee_public_ip.ip_address
}
