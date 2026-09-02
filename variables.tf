variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "West Europe"
}

variable "project_name" {
  description = "Short name used as prefix for resource names"
  type        = string
  default     = "hybrid-lab"
}

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "aks_node_count" {
  description = "Number of nodes in the default AKS node pool"
  type        = number
  default     = 2
}

variable "aks_vm_size" {
  description = "VM size for AKS nodes"
  type        = string
  default     = "Standard_D2s_v3"
}