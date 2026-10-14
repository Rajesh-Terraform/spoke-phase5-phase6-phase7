variable "name" {
  description = "Name prefix for routing resources."
  type        = string
}

variable "vpc_id" {
  description = "ID of the spoke VPC."
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs."
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Private subnet IDs."
  type        = list(string)
}

variable "tags" {
  description = "Tags applied to routing resources."
  type        = map(string)
}
