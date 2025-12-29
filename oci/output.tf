
# ============================================================================
# OUTPUTS
# ============================================================================

# VCN Outputs
output "vcn_id" {
  value       = module.oci_network.vcn_id
  description = "OCID of the OCI VCN"
}

output "vcn_cidr" {
  value       = module.oci_network.vcn_cidr
  description = "CIDR block of the OCI VCN"
}

# Subnet Outputs
output "public_subnet_id" {
  value       = module.oci_network.public_subnet_id
  description = "OCID of the Public Subnet"
}

output "private_subnet_id" {
  value       = module.oci_network.private_subnet_id
  description = "OCID of the Private Subnet"
}

# DRG Outputs
output "drg_id" {
  value       = module.oci_network.drg_id
  description = "OCID of the Dynamic Routing Gateway"
}

# IPSec Outputs
output "ipsec_connection_id" {
  value       = module.oci_network.ipsec_connection_id
  description = "OCID of the IPSec connection"
}

output "oci_vpn_tunnel_public_ip" {
  value       = module.oci_network.oci_vpn_tunnel_public_ip
  description = "OCI VPN Tunnel Public IP - USE THIS IN AWS CUSTOMER GATEWAY"
}

output "oci_vpn_tunnel_status" {
  value       = module.oci_network.oci_vpn_tunnel_status
  description = "Status of the OCI IPSec tunnel"
}

output "cpe_id" {
  value       = module.oci_network.cpe_id
  description = "OCID of the Customer Premises Equipment"
}