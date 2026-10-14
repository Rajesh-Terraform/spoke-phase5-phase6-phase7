resource "aws_internet_gateway" "this" {
  vpc_id = var.vpc_id

  tags = merge(var.tags, {
    Name  = "${var.name}-igw"
    Phase = "6"
  })
}

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = merge(var.tags, {
    Name  = "${var.name}-nat-eip"
    Phase = "6"
  })
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = var.public_subnet_ids[0]

  depends_on = [aws_internet_gateway.this]

  tags = merge(var.tags, {
    Name  = "${var.name}-nat"
    Phase = "6"
  })
}

resource "aws_route_table" "public" {
  count  = length(var.public_subnet_ids)
  vpc_id = var.vpc_id

  tags = merge(var.tags, {
    Name  = "${var.name}-public-${count.index + 1}"
    Phase = "6"
    Tier  = "public"
  })
}

resource "aws_route" "public_internet" {
  count = length(var.public_subnet_ids)

  route_table_id         = aws_route_table.public[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  count = length(var.public_subnet_ids)

  subnet_id      = var.public_subnet_ids[count.index]
  route_table_id = aws_route_table.public[count.index].id
}

resource "aws_route_table" "private" {
  count  = length(var.private_subnet_ids)
  vpc_id = var.vpc_id

  tags = merge(var.tags, {
    Name  = "${var.name}-private-${count.index + 1}"
    Phase = "6"
    Tier  = "private"
  })
}

resource "aws_route" "private_internet" {
  count = length(var.private_subnet_ids)

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this.id
}

resource "aws_route_table_association" "private" {
  count = length(var.private_subnet_ids)

  subnet_id      = var.private_subnet_ids[count.index]
  route_table_id = aws_route_table.private[count.index].id
}
