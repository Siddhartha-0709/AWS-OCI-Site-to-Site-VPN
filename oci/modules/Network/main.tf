# ============================================================================
# VARIABLES
# ============================================================================
variable "compartment_id" {
  description = "OCI Compartment OCID"
  type        = string
}

variable "aws_vpn_gateway_ip" {
  description = "AWS Virtual Private Gateway public IP address"
  type        = string
}

variable "aws_vpc_cidr" {
  description = "AWS VPC CIDR block"
  type        = string
  default     = "192.168.0.0/16"
}

variable "oci_vcn_cidr" {
  description = "OCI VCN CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "tunnel_1_shared_secret" {
  description = "Shared secret for IPSec Tunnel 1"
  type        = string
  sensitive   = true
  default     = "qwertyuiopasdfghjkl"
}

# ============================================================================
# VCN AND NETWORKING RESOURCES
# ============================================================================
resource "oci_core_vcn" "vcn_oci_mumbai" {
  compartment_id = var.compartment_id
  cidr_block     = var.oci_vcn_cidr
  display_name   = "VCN-OCI-Mumbai"
}

resource "oci_core_internet_gateway" "internet_gateway" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn_oci_mumbai.id
  display_name   = "IGW-OCI-Mumbai"
  enabled        = true
}

# ============================================================================
# DYNAMIC ROUTING GATEWAY (DRG)
# ============================================================================
resource "oci_core_drg" "oci_drg" {
  compartment_id = var.compartment_id
  display_name   = "DRG-OCI-Mumbai"
}

resource "oci_core_drg_attachment" "oci_drg_attachment" {
  drg_id       = oci_core_drg.oci_drg.id
  display_name = "DRG-Attachment-Mumbai-VCN"

  network_details {
    id   = oci_core_vcn.vcn_oci_mumbai.id
    type = "VCN"
  }
}

# ============================================================================
# ROUTE TABLES
# ============================================================================
resource "oci_core_route_table" "public_route_table" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn_oci_mumbai.id
  display_name   = "RT-Public-Subnet"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.internet_gateway.id
    description       = "Default route to Internet Gateway"
  }
}

resource "oci_core_route_table" "private_route_table" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn_oci_mumbai.id
  display_name   = "RT-Private-Subnet"

  route_rules {
    destination       = var.aws_vpc_cidr
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_drg.oci_drg.id
    description       = "Route to AWS VPC via DRG"
  }
}

# ============================================================================
# SUBNETS
# ============================================================================
resource "oci_core_subnet" "public_subnet" {
  compartment_id    = var.compartment_id
  vcn_id            = oci_core_vcn.vcn_oci_mumbai.id
  cidr_block        = "10.0.0.0/24"
  display_name      = "Subnet-Public"
  route_table_id    = oci_core_route_table.public_route_table.id
  dns_label         = "public"
  security_list_ids = [oci_core_vcn.vcn_oci_mumbai.default_security_list_id]
}

resource "oci_core_subnet" "private_subnet" {
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.vcn_oci_mumbai.id
  cidr_block                 = "10.0.1.0/24"
  display_name               = "Subnet-Private"
  route_table_id             = oci_core_route_table.private_route_table.id
  prohibit_public_ip_on_vnic = true
  dns_label                  = "private"
  security_list_ids          = [oci_core_vcn.vcn_oci_mumbai.default_security_list_id]
}

# ============================================================================
# IPSEC VPN CONNECTION TO AWS
# ============================================================================

# Customer Premises Equipment (represents AWS VPN Gateway)
resource "oci_core_cpe" "aws_vpn_gateway" {
  compartment_id = var.compartment_id
  ip_address     = var.aws_vpn_gateway_ip
  display_name   = "CPE-AWS-VPN-Gateway"
}

# IPSec Connection
resource "oci_core_ipsec" "oci_to_aws_ipsec" {
  compartment_id = var.compartment_id
  cpe_id         = oci_core_cpe.aws_vpn_gateway.id
  drg_id         = oci_core_drg.oci_drg.id
  display_name   = "IPSec-OCI-to-AWS"
  static_routes  = [var.aws_vpc_cidr]
}

# Fetch IPSec Tunnel Information
data "oci_core_ipsec_connection_tunnels" "ipsec_tunnels" {
  ipsec_id = oci_core_ipsec.oci_to_aws_ipsec.id
}

# Configure Primary IPSec Tunnel
resource "oci_core_ipsec_connection_tunnel_management" "primary_tunnel" {
  ipsec_id  = oci_core_ipsec.oci_to_aws_ipsec.id
  tunnel_id = data.oci_core_ipsec_connection_tunnels.ipsec_tunnels.ip_sec_connection_tunnels[0].id

  display_name  = "IPSec-Tunnel-Primary-OCI-to-AWS"
  routing       = "STATIC"
  ike_version   = "V2"
  shared_secret = var.tunnel_1_shared_secret

  # Traffic Selectors
  encryption_domain_config {
    oracle_traffic_selector = [var.oci_vcn_cidr]
    cpe_traffic_selector    = [var.aws_vpc_cidr]
  }

  # Dead Peer Detection
  dpd_config {
    dpd_mode           = "RESPOND_ONLY"
    dpd_timeout_in_sec = 30
  }
}

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

# IPSec Connection Outputs
output "ipsec_connection_id" {
  value       = oci_core_ipsec.oci_to_aws_ipsec.id
  description = "OCID of the IPSec connection"
}

output "oci_vpn_tunnel_public_ip" {
  value       = data.oci_core_ipsec_connection_tunnels.ipsec_tunnels.ip_sec_connection_tunnels[0].vpn_ip
  description = "OCI IPSec Tunnel public IP - Use this as Customer Gateway IP in AWS"
}

output "oci_vpn_tunnel_status" {
  value       = data.oci_core_ipsec_connection_tunnels.ipsec_tunnels.ip_sec_connection_tunnels[0].status
  description = "Status of the OCI IPSec tunnel"
}

output "cpe_id" {
  value       = oci_core_cpe.aws_vpn_gateway.id
  description = "OCID of the Customer Premises Equipment"
}

# ============================================================================
# IMPORTANT NOTES FOR AWS CONFIGURATION
# ============================================================================
# When configuring AWS side:
# 1. Use the "oci_vpn_tunnel_public_ip" output as the Customer Gateway IP
# 2. Set the shared secret to: qwertyuiopasdfghjkl
# 3. Use Static Routing (not BGP)
# 4. Configure these parameters:
#    - IKE Version: IKEv2
#    - Phase 1 Encryption: AES-256
#    - Phase 1 Integrity: SHA-256
#    - Phase 1 DH Group: Group 14 (2048-bit)
#    - Phase 2 Encryption: AES-256
#    - Phase 2 Integrity: SHA-256
#    - Phase 2 DH Group: Group 14
#    - Lifetime: Phase 1 = 28800 seconds, Phase 2 = 3600 seconds
# ============================================================================