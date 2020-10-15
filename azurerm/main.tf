terraform {
  required_version = "~> 0.13.2"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.31.1"
    }
  }
}

provider "azurerm" {
  features {}
}

locals {
  public_ip_name = "${var.tw_vm_name}-pip-0"
}

resource "azurerm_resource_group" "rg" {
  name     = var.tw_rg_name
  location = "East US"
  tags     = var.tw-tags
}

module "network" {
  source              = "Azure/network/azurerm"
  version             = "3.2.1"
  resource_group_name = azurerm_resource_group.rg.name
  vnet_name           = var.tw_vnet_name
  address_space       = "10.0.0.0/16"
  subnet_prefixes     = ["10.0.1.0/24"]
  subnet_names        = [var.tw_subnet_name]

  tags = var.tw-tags

  depends_on = [azurerm_resource_group.rg]
}

# For future enhancements
#resource "tls_private_key" "keys" {
#  algorithm   = "RSA"
#}

module "compute" {
  source                        = "Azure/compute/azurerm"
  version                       = "3.7.0"
  public_ip_dns                 = [local.public_ip_name]
  admin_username                = var.tw_username
  location                      = var.tw_location
  resource_group_name           = azurerm_resource_group.rg.name
  vm_hostname                   = var.tw_vm_name
  nb_public_ip                  = 1
  remote_port                   = "22"
  nb_instances                  = 1
  vm_os_publisher               = "OpenLogic"
  vm_os_offer                   = "CentOS"
  vm_os_sku                     = "8.0"
  vnet_subnet_id                = module.network.vnet_subnets[0]
  boot_diagnostics              = true
  delete_os_disk_on_termination = true
  enable_ssh_key                = true
  vm_size                       = "Standard_D2s_v3"
  ssh_key                       = var.ssh_public_key
  #ssh_key                       = tls_private_key.keys.private_key_pem

  tags = var.tw-tags

  depends_on = [azurerm_resource_group.rg]
}

resource "time_sleep" "wait_60_seconds" {
  depends_on      = [module.compute]
  create_duration = "60s"
}

data "azurerm_public_ip" "host_ip" {
  name                = local.public_ip_name
  resource_group_name = var.tw_rg_name

  depends_on = [module.compute, time_sleep.wait_60_seconds]
}

resource "null_resource" "chef" {
  connection {
    host = data.azurerm_public_ip.host_ip.ip_address
    type = "ssh"
    user = var.tw_username
    #private_key = tls_private_key.keys.public_key_pem
    private_key = file(var.ssh_key_file)
  }

  provisioner "chef" {
    environment             = "_default"
    run_list                = [var.chef_runlist]
    node_name               = var.tw_vm_name
    server_url              = var.chef_server_url
    recreate_client         = true
    user_name               = var.chef_server_user_name
    user_key                = file(var.chef_server_user_key)
    fetch_chef_certificates = true
    client_options          = ["chef_license 'accept'"]
  }

  depends_on = [module.compute, time_sleep.wait_60_seconds]
}

resource "azurerm_network_security_rule" "http" {
  name                        = "allow_remote_80_in_all"
  resource_group_name         = var.tw_rg_name
  description                 = "Allow http protocol in from all locations"
  priority                    = 102
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefixes     = ["0.0.0.0/0"]
  destination_address_prefix  = "*"
  network_security_group_name = module.compute.network_security_group_name
}

output "mediawiki_ip" {
  value = data.azurerm_public_ip.host_ip.ip_address
}
