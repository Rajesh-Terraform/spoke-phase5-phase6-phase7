variable "name" {
  description = "Name prefix for peering resources."
  type        = string
}

variable "spoke_vpc_id" {
  description = "ID of the spoke VPC."
  type        = string
}

variable "spoke_cidr_block" {
  description = "IPv4 CIDR range of the spoke VPC."
  type        = string
}

variable "spoke_route_table_ids" {
  description = "Spoke route table IDs that need routes to the hub."
  type        = list(string)
}

variable "hub_vpc_id" {
  description = "ID of the existing hub VPC."
  type        = string
}

variable "hub_cidr_block" {
  description = "IPv4 CIDR range of the existing hub VPC."
  type        = string
}

variable "hub_route_table_ids" {
  description = "Hub route table IDs that need routes back to the spoke."
  type        = list(string)
}

variable "tags" {
  description = "Tags applied to peering resources."
  type        = map(string)
}
