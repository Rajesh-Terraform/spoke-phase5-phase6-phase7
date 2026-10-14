resource "aws_vpc_peering_connection" "this" {
  vpc_id      = var.spoke_vpc_id
  peer_vpc_id = var.hub_vpc_id
  auto_accept = true

  tags = merge(var.tags, {
    Name  = "${var.name}-to-hub"
    Phase = "7"
  })
}

resource "aws_route" "spoke_to_hub" {
  for_each = toset(var.spoke_route_table_ids)

  route_table_id            = each.value
  destination_cidr_block    = var.hub_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
}

resource "aws_route" "hub_to_spoke" {
  for_each = toset(var.hub_route_table_ids)

  route_table_id            = each.value
  destination_cidr_block    = var.spoke_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
}
