
# ============================================================================
# OUTPUTS
# ============================================================================

# VPC Outputs
output "vpc_id" {
  value       = aws_vpc.vpc_aws_mumbai.id
  description = "AWS VPC ID"
}

output "vpc_cidr" {
  value       = aws_vpc.vpc_aws_mumbai.cidr_block
  description = "AWS VPC CIDR block"
}

# Subnet Outputs
output "public_subnet_id" {
  value       = aws_subnet.public_subnet.id
  description = "Public Subnet ID"
}

output "private_subnet_id" {
  value       = aws_subnet.private_subnet.id
  description = "Private Subnet ID"
}

# Security Group
output "security_group_id" {
  value       = aws_security_group.main_sg.id
  description = "Main Security Group ID"
}

# VPN Gateway
output "vpn_gateway_id" {
  value       = aws_vpn_gateway.vgw.id
  description = "Virtual Private Gateway ID"
}

# Customer Gateway
output "customer_gateway_id" {
  value       = aws_customer_gateway.oci_cgw.id
  description = "Customer Gateway ID"
}

# VPN Connection
output "vpn_connection_id" {
  value       = aws_vpn_connection.aws_to_oci_vpn.id
  description = "Site-to-Site VPN Connection ID"
}

# AWS Tunnel Endpoints (Use this as CPE IP in OCI)
output "aws_tunnel_1_public_ip" {
  value       = aws_vpn_connection.aws_to_oci_vpn.tunnel1_address
  description = "AWS VPN Tunnel 1 public IP - Use this as CPE IP address in OCI"
}

# output "aws_tunnel_1_status" {
#   value       = aws_vpn_connection.aws_to_oci_vpn.tunnel1_status
#   description = "AWS Tunnel 1 connection status"
# }

output "aws_tunnel_1_inside_cidr" {
  value       = aws_vpn_connection.aws_to_oci_vpn.tunnel1_inside_cidr
  description = "AWS Tunnel 1 inside CIDR (for BGP if needed)"
}

# Sensitive outputs
output "tunnel_1_preshared_key" {
  value       = aws_vpn_connection.aws_to_oci_vpn.tunnel1_preshared_key
  description = "Tunnel 1 pre-shared key"
  sensitive   = true
}