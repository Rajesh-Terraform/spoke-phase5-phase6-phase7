variable "name" {
  description = "Name prefix for the VPC and subnets."
  type        = string
}

variable "vpc_cidr_block" {
  description = "IPv4 CIDR range for the VPC."
  type        = string
}

variable "availability_zones" {
  description = "Availability zones to use, or an empty list to select available zones automatically."
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "IPv4 CIDR ranges for public subnets."
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_cidrs) > 0
    error_message = "At least one public subnet CIDR is required."
  }
}

variable "private_subnet_cidrs" {
  description = "IPv4 CIDR ranges for private subnets."
  type        = list(string)
}

variable "tags" {
  description = "Tags applied to VPC and subnet resources."
  type        = map(string)
}
