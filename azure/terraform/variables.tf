variable "state_resource_group_name" {
  type = string
}

variable "state_storage_account_name" {
  type = string
}

variable "state_container_name" {
  type = string
}

variable "project_name" {
  type = string
  default = "TestProduct"
}

variable "environment" {
  description = "Environment name, e.g. Dev, Staging, Prod"
  type = string
}

variable "location" {
  type = string
  default = "west europe"
}
