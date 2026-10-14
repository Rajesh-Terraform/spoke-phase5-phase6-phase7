variable "aws_region" {
  description = "AWS region for all resources."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefix used for resource names."
  type        = string
  default     = "spoke"
}

variable "vpc_cidr_block" {
  description = "IPv4 CIDR range for the spoke VPC."
  type        = string
  default     = "10.20.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones for subnets. Leave empty to use the first available zones in the selected region."
  type        = list(string)
  default     = []
}

variable "public_subnet_cidrs" {
  description = "IPv4 CIDR ranges for public subnets, one per availability zone."
  type        = list(string)
  default     = ["10.20.1.0/24", "10.20.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "IPv4 CIDR ranges for private subnets, one per availability zone."
  type        = list(string)
  default     = ["10.20.11.0/24", "10.20.12.0/24"]
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
  }
}

variable "hub_peering" {
  description = "Existing hub details for optional phase 7 VPC peering."
  type = object({
    enabled         = bool
    vpc_id          = string
    cidr_block      = string
    route_table_ids = list(string)
  })
  default = {
    enabled         = false
    vpc_id          = ""
    cidr_block      = ""
    route_table_ids = []
  }

  validation {
    condition = !var.hub_peering.enabled || (
      length(trimspace(var.hub_peering.vpc_id)) > 0 &&
      length(trimspace(var.hub_peering.cidr_block)) > 0 &&
      length(var.hub_peering.route_table_ids) > 0
    )
    error_message = "When hub peering is enabled, provide the hub VPC ID, CIDR block, and at least one hub route table ID."
  }
}
