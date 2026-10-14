output "public_route_table_ids" {
  description = "IDs of route tables associated with public subnets."
  value       = aws_route_table.public[*].id
}

output "private_route_table_ids" {
  description = "IDs of route tables associated with private subnets."
  value       = aws_route_table.private[*].id
}

output "nat_gateway_id" {
  description = "ID of the shared NAT gateway."
  value       = aws_nat_gateway.this.id
}
