output "spoke_vpc_id" {
  description = "ID of the spoke VPC."
  value       = module.phase5_vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = module.phase5_vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets."
  value       = module.phase5_vpc.private_subnet_ids
}

output "public_route_table_ids" {
  description = "IDs of the public route tables."
  value       = module.phase6_routing.public_route_table_ids
}

output "private_route_table_ids" {
  description = "IDs of the private route tables."
  value       = module.phase6_routing.private_route_table_ids
}

output "nat_gateway_id" {
  description = "ID of the shared NAT gateway."
  value       = module.phase6_routing.nat_gateway_id
}

output "hub_peering_connection_id" {
  description = "ID of the hub peering connection, or null when phase 7 is disabled."
  value       = try(module.phase7_hub_peering[0].peering_connection_id, null)
}
