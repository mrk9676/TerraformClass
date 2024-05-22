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

variable "vnet_cidr" {
  type = string
  default = "192.168.0.0/16"
}

variable "subnet_names" {
  type  = list(string)
  default = [ "ui", "app", "db", "network", "storage" ]
}

variable "storage_containers" {
  type  = map(object({
    name = string
    container_access_type = string
    
  }))
  default = {
    "container1" = {
      name = "container-A"
      container_access_type = "container"
      
    },
    "container2" = {
      name = "container-B"
      container_access_type = "blob"
      
    },
    "container3" = {
      name = "container-C"
      container_access_type = "private"
     
    }
    
  }
  description = "It won't accept special characters or capital letters"
}