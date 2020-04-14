variable "basename" {
  type        = string
  description = "The base name for all resources"
}

variable "resource_group_name" {
  type        = string
  description = "rg name. Use only lowercase letters and numbers"
  default     = "functions-storage-managed-identity"
}

variable "location" {
  type        = string
  description = "Azure region where to create resources."
  default     = "West US"
}