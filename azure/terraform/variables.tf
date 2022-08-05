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
