variable "rg_name" {
    type    = string
    default = "tf-rg"
}

variable "environment" {
  type      = string
  default   = "dv"
}

variable "vnet_name" {
  type      = string
  default   = "tf-vnet"
}

variable "soft_delete_retention_days" {
  type      = number
  default   = 7
}

variable "kv_name" {
  type = string
  default = "tf-keyvault-14052024"
}

variable "location" {
  type = string
  default = "eastus"
}

variable "subnetname" {
  type = string
  default = "tf-subnet"
}