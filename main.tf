terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.100.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "terraform-backedn-storage-accounts"  # Can be passed via `-backend-config=`"resource_group_name=<resource group name>"` in the `init` command.
    storage_account_name = "ramdevopssa"                      # Can be passed via `-backend-config=`"storage_account_name=<storage account name>"` in the `init` command.
    container_name       = "terraform-statefile"                       # Can be passed via `-backend-config=`"container_name=<container name>"` in the `init` command.
    key                  = "myterraformstate"        # Can be passed via `-backend-config=`"key=<blob key name>"` in the `init` command.
    #use_azuread_auth     = true                            # Can also be set via `ARM_USE_AZUREAD` environment variable.
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "myrg" {
  name        = "${var.environment}-${var.rg_name}"
  location    = "WestUS"
  tags        = {
    "Team"    = "DevOps"
    "source"  = "Terraform"
  }   
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "mykv" {
name                          = "${var.environment}-${var.kv_name}"
  location                    = azurerm_resource_group.myrg.location
  resource_group_name         = azurerm_resource_group.myrg.name
  sku_name                    = "standard"
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = var.soft_delete_retention_days

  depends_on                  = [ azurerm_resource_group.myrg ]
}


resource "azurerm_virtual_network" "my_vm_vnet" {
  name                = "${var.environment}-${var.vnet_name}"
  resource_group_name = azurerm_resource_group.myrg.name
  address_space       = [var.vnet_cidr]
  location            = var.location

  depends_on          = [ azurerm_resource_group.myrg ]
}

resource "azurerm_subnet" "my_subnet" {
  count                = length(var.subnet_names)
  name                 = var.subnet_names[count.index]
  resource_group_name  = azurerm_resource_group.myrg.name
  virtual_network_name = azurerm_virtual_network.my_vm_vnet.name
  address_prefixes     = [cidrsubnet(var.vnet_cidr, 8, count.index)]

  depends_on          = [ azurerm_virtual_network.my_vm_vnet ]
}

resource "azurerm_network_interface" "my_nic" {
  name                = "tf-vm-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.myrg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.my_subnet[3].id
    private_ip_address_allocation = "Dynamic"
  }

  depends_on                      = [ azurerm_subnet.my_subnet ]
}

resource "azurerm_linux_virtual_machine" "mytfvm" { 
  name                  = "tf-virtual-machine-${var.environment}"
  location              = var.location
  resource_group_name   = azurerm_resource_group.myrg.name
  admin_username        = "mrk9676"
  admin_password        = "Myvmpassword@12345"
  disable_password_authentication= false
  network_interface_ids = [ azurerm_network_interface.my_nic.id]
  os_disk  {
    caching             = "None"
    storage_account_type  = "Standard_LRS"
  }
  source_image_reference {
    publisher             = "Canonical"
    offer                 = "0001-com-ubuntu-server-jammy"
    sku                   = "22_04-lts"
    version               = "latest"
  }
   size                   = "Standard_B1s"

   depends_on             = [ azurerm_network_interface.my_nic ]
}


resource "azurerm_storage_account" "my_tf_storage_account" {
  name                = var.environment == "dv" ? "ramdv22052024" : "ramprod22052024"
  resource_group_name = azurerm_resource_group.myrg.name
  location            = var.location
  account_kind        = "StorageV2"
  account_tier        = "Standard"
  account_replication_type = "LRS"
  cross_tenant_replication_enabled = false
  access_tier         = "Hot"
}


resource "azurerm_storage_container" "example" {
  for_each              = var.storage_containers
  name                  = replace(lower(each.value.name), "-", "")
  storage_account_name  = azurerm_storage_account.my_tf_storage_account.name
  container_access_type = each.value.container_access_type
}