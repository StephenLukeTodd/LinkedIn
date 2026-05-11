# =============================================================================
# Input Variables for AKS with Key Vault Integration
# =============================================================================

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

