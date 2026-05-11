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

variable "appId" {
  description = "Azure Service Principal client ID for AKS authentication"
  type        = string
  sensitive   = true
}

variable "password" {
  description = "Azure Service Principal client secret for AKS authentication"
  type        = string
  sensitive   = true
}

variable "tenant_id" {
  description = "Azure AD tenant ID for Key Vault access"
  type        = string
  sensitive   = true
}
