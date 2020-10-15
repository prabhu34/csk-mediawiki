variable "tw-tags" {
  default = {
    tw-app    = "tw-mediawiki"
    tw-env    = "dev"
    installed = "terraform"
  }
}

variable "tw_rg_name" {
  default = "tw-mw-tf"
}

variable "tw_vnet_name" {
  default = "tw-mw-tf-vnet"
}

variable "tw_subnet_name" {
  default = "tw-mw-tf-vnet-sub1"
}

variable "tw_vm_name" {
  default = "tw-mw-tf-vm"
}

variable "tw_location" {
  default = "East US"
}

variable "tw_username" {
  default = ""
}

variable "tw_password" {
  default = ""
}

variable "chef_server_url" {
  default = ""
}

variable "chef_server_user_name" {
  default = ""
}

variable "chef_server_user_key" {
  default = ""
}

variable "ssh_key_file" {
  default = ""
}

variable "chef_runlist" {
  default = "tw-mediawiki::default"
}

variable "ssh_public_key" {
  default = ""
}
