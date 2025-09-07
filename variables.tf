variable "location" {
  description = "Azure region to deploy resources"
  default     = "East US"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  default     = "iconnect"
}

variable "project_name" {
  description = "Project name for resource naming"
  default     = "iconnect"
}
