module "phase5_vpc" {
  source = "./modules/phase5-vpc"

  name                 = var.project_name
  vpc_cidr_block       = var.vpc_cidr_block
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  tags                 = var.tags
}

module "phase6_routing" {
  source = "./modules/phase6-routing"

  name               = var.project_name
  vpc_id             = module.phase5_vpc.vpc_id
  public_subnet_ids  = module.phase5_vpc.public_subnet_ids
  private_subnet_ids = module.phase5_vpc.private_subnet_ids
  tags               = var.tags
}

module "phase7_hub_peering" {
  count  = var.hub_peering.enabled ? 1 : 0
  source = "./modules/phase7-hub-peering"

  name                  = var.project_name
  spoke_vpc_id          = module.phase5_vpc.vpc_id
  spoke_cidr_block      = var.vpc_cidr_block
  spoke_route_table_ids = concat(module.phase6_routing.public_route_table_ids, module.phase6_routing.private_route_table_ids)
  hub_vpc_id            = var.hub_peering.vpc_id
  hub_cidr_block        = var.hub_peering.cidr_block
  hub_route_table_ids   = var.hub_peering.route_table_ids
  tags                  = var.tags
}
