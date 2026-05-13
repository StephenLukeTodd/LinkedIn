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


variable "video_app_path" {
  description = "Path to the video player app source (used for Kubernetes template generation)"
  type        = string
  default     = "${path.module}/video-player"
}


