# ============================================================================
# NETWORK MODULE
# ============================================================================
module "network" {
  source = "./modules/network"

  aws_region            = var.aws_region
  oci_tunnel_public_ip  = var.oci_tunnel_public_ip
  tunnel_1_shared_secret = var.tunnel_1_shared_secret
  aws_vpc_cidr          = "192.168.0.0/16"
  oci_vcn_cidr          = "10.0.0.0/16"
}

# ============================================================================
# EC2 INSTANCE MODULE
# ============================================================================

module "compute" {
  source            = "./modules/compute"
  subnet_id         =  module.network.private_subnet_id
  security_group_id = [module.network.security_group_id]
  depends_on        = [module.network]
}
