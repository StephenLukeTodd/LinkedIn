variable "resource_group_name" {
  description = "Name of the Azure resource group"
  type        = string
  default     = "MooRG"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "westus"
}

variable "appId" {
  description = "Azure Service Principal client ID"
  type        = string
}

variable "password" {
  description = "Azure Service Principal client secret"
  type        = string
  sensitive   = true
}
