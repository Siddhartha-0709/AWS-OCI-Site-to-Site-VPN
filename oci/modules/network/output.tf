# ============================================================================
# OUTPUTS
# ============================================================================

# VCN Outputs
output "vcn_id" {
  value       = oci_core_vcn.vcn_oci_mumbai.id
  description = "OCID of the OCI VCN"
}

output "vcn_cidr" {
  value       = oci_core_vcn.vcn_oci_mumbai.cidr_block
  description = "CIDR block of the OCI VCN"
}

# Subnet Outputs
output "public_subnet_id" {
  value       = oci_core_subnet.public_subnet.id
  description = "OCID of the Public Subnet"
}

output "private_subnet_id" {
  value       = oci_core_subnet.private_subnet.id
  description = "OCID of the Private Subnet"
}

# DRG Outputs
output "drg_id" {
  value       = oci_core_drg.oci_drg.id
  description = "OCID of the Dynamic Routing Gateway"
}

# IPSec Connection Outputs (only if created)
output "ipsec_connection_id" {
  value       = var.create_ipsec ? oci_core_ipsec.oci_to_aws_ipsec[0].id : "Not created yet"
  description = "OCID of the IPSec connection"
}

output "oci_vpn_tunnel_public_ip" {
  value       = var.create_ipsec ? data.oci_core_ipsec_connection_tunnels.ipsec_tunnels[0].ip_sec_connection_tunnels[0].vpn_ip : "Not created yet - run with create_ipsec=true"
  description = "OCI IPSec Tunnel public IP - Use this as Customer Gateway IP in AWS"
}

output "oci_vpn_tunnel_status" {
  value       = var.create_ipsec ? data.oci_core_ipsec_connection_tunnels.ipsec_tunnels[0].ip_sec_connection_tunnels[0].status : "Not created yet"
  description = "Status of the OCI IPSec tunnel"
}

output "cpe_id" {
  value       = var.create_ipsec ? oci_core_cpe.aws_vpn_gateway[0].id : "Not created yet"
  description = "OCID of the Customer Premises Equipment"
}
