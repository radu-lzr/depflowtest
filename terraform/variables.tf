variable "storage_account_name" {
  type        = string
  default     = "stterraformradutest"
  description = "The name of the storage account for storing Terraform state"
}

variable "resource_group_name" {
  type        = string
  default     = "rg-terraform"
  description = "The name of the resource group for storing Terraform state"
}
