variable "oci_cpe_public_ip" {
  description = "OCI tunnel public IP (use 1.1.1.1 initially)"
  type        = string
}

variable "use_real_cgw" {
  description = "Set to true to switch from temp CGW to real CGW (after OCI is configured)"
  type        = bool
}




module "network" {
  source            = "./modules/vpc"
  oci_cpe_public_ip = var.oci_cpe_public_ip
  use_real_cgw      = var.use_real_cgw
}

module "compute" {
  source            = "./modules/ec2"
  subnet_id         =  module.network.private_subnet_id
  security_group_id = [module.network.security_group_id]
  depends_on        = [module.network]
}





output "aws_tunnel_1_outside_ip" {
  value       = module.network.aws_tunnel_1_outside_ip
  depends_on  = [module.network]
}

output "aws_tunnel_2_outside_ip" {
  value       = module.network.aws_tunnel_2_outside_ip
  depends_on  = [module.network]
}

output "aws_tunnel_1_preshared_key" {
  value       = module.network.aws_tunnel_1_preshared_key
  sensitive   = true
  description = "AWS VPN Tunnel 1 Pre-shared Key"
  depends_on  = [module.network]
}

output "aws_ec2_instance_private_ip" {
  value       = module.compute.instance_private_ip
  depends_on  = [module.compute]
}