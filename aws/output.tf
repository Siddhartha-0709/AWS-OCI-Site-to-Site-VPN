
# ============================================================================
# OUTPUTS
# ============================================================================

# VPC Outputs
output "vpc_id" {
  value       = module.network.vpc_id
  description = "AWS VPC ID"
}

output "vpc_cidr" {
  value       = module.network.vpc_cidr
  description = "AWS VPC CIDR block"
}

# Subnet Outputs
output "public_subnet_id" {
  value       = module.network.public_subnet_id
  description = "Public Subnet ID"
}

output "private_subnet_id" {
  value       = module.network.private_subnet_id
  description = "Private Subnet ID"
}

# Security Group
output "security_group_id" {
  value       = module.network.security_group_id
  description = "Main Security Group ID"
}

# VPN Gateway
output "vpn_gateway_id" {
  value       = module.network.vpn_gateway_id
  description = "Virtual Private Gateway ID"
}

# Customer Gateway
output "customer_gateway_id" {
  value       = module.network.customer_gateway_id
  description = "Customer Gateway ID pointing to OCI"
}

# VPN Connection
output "vpn_connection_id" {
  value       = module.network.vpn_connection_id
  description = "Site-to-Site VPN Connection ID"
}

# AWS Tunnel Information (CRITICAL - Use this in OCI CPE)
output "aws_tunnel_1_public_ip" {
  value       = module.network.aws_tunnel_1_public_ip
  description = "AWS VPN Tunnel 1 Public IP - USE THIS AS CPE IP IN OCI"
}

output "aws_tunnel_1_inside_cidr" {
  value       = module.network.aws_tunnel_1_inside_cidr
  description = "AWS Tunnel 1 inside CIDR"
}

# Sensitive outputs
output "tunnel_1_preshared_key" {
  value       = module.network.tunnel_1_preshared_key
  description = "Tunnel 1 pre-shared key"
  sensitive   = true
}