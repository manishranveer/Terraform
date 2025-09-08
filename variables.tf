variable "project_name" {
  description = "Base project name (lowercase recommended, letters/numbers/hyphen)"
  type        = string
  default     = "iconnect"
}

variable "location" {
  description = "Azure region to deploy to"
  type        = string
  default     = "centralus"
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default = {
    Environment = "prod"
    Owner       = "team"
  }
}
