data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  subnet_count = length(var.public_subnet_cidrs)
  zones = length(var.availability_zones) > 0 ? var.availability_zones : slice(
    data.aws_availability_zones.available.names,
    0,
    local.subnet_count
  )
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  lifecycle {
    precondition {
      condition     = length(var.private_subnet_cidrs) == local.subnet_count
      error_message = "The number of private subnet CIDRs must match the number of public subnet CIDRs."
    }

    precondition {
      condition     = length(var.availability_zones) == 0 || length(var.availability_zones) == local.subnet_count
      error_message = "Provide either no availability zones or one availability zone per public subnet CIDR."
    }
  }

  tags = merge(var.tags, {
    Name  = "${var.name}-vpc"
    Phase = "5"
  })
}

resource "aws_subnet" "public" {
  count = local.subnet_count

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = local.zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name  = "${var.name}-public-${count.index + 1}"
    Phase = "5"
    Tier  = "public"
  })
}

resource "aws_subnet" "private" {
  count = local.subnet_count

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = local.zones[count.index]

  tags = merge(var.tags, {
    Name  = "${var.name}-private-${count.index + 1}"
    Phase = "5"
    Tier  = "private"
  })
}
