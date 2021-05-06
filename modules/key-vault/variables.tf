variable "existingResourceGroupName" {
  description = "Main Resource Group Name"
  type        = string
}

variable "adminuserPassword" {
  description = "Password for adminuser of Virtual Machine"
  type        = string
  sensitive   = true
}