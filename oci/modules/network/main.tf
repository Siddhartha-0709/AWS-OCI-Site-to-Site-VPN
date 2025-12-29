# ============================================================================
# VCN AND NETWORKING RESOURCES
# ============================================================================
resource "oci_core_vcn" "vcn_oci_mumbai" {
  compartment_id = var.compartment_id
  cidr_block     = var.oci_vcn_cidr
  display_name   = "OCI VCN Mumbai"
  
  # Enable DNS for the VCN
  dns_label = "ocimumbai"
}

resource "oci_core_internet_gateway" "internet_gateway" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn_oci_mumbai.id
  display_name   = "Internet Gateway OCI Mumbai"
  enabled        = true
}

# ============================================================================
# DYNAMIC ROUTING GATEWAY (DRG)
# ============================================================================
resource "oci_core_drg" "oci_drg" {
  compartment_id = var.compartment_id
  display_name   = "Dynamic Routing Gateway OCI Mumbai"
}

resource "oci_core_drg_attachment" "oci_drg_attachment" {
  drg_id       = oci_core_drg.oci_drg.id
  display_name = "VCN-DRG-Attachment"

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
  display_name   = "Public Subnet Route Table"

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
  display_name   = "Private Subnet Route Table"

  # Only add AWS route if IPSec is being created
  dynamic "route_rules" {
    for_each = var.create_ipsec ? [1] : []
    content {
      destination       = var.aws_vpc_cidr
      destination_type  = "CIDR_BLOCK"
      network_entity_id = oci_core_drg.oci_drg.id
      description       = "Route to AWS VPC via DRG"
    }
  }
}

# ============================================================================
# SUBNETS
# ============================================================================
resource "oci_core_subnet" "public_subnet" {
  compartment_id    = var.compartment_id
  vcn_id            = oci_core_vcn.vcn_oci_mumbai.id
  cidr_block        = "10.0.0.0/24"
  display_name      = "Public Subnet"
  route_table_id    = oci_core_route_table.public_route_table.id
  dns_label         = "public"
  security_list_ids = [oci_core_vcn.vcn_oci_mumbai.default_security_list_id]
}

resource "oci_core_subnet" "private_subnet" {
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.vcn_oci_mumbai.id
  cidr_block                 = "10.0.1.0/24"
  display_name               = "Private Subnet"
  route_table_id             = oci_core_route_table.private_route_table.id
  prohibit_public_ip_on_vnic = true
  dns_label                  = "private"
  security_list_ids          = [oci_core_vcn.vcn_oci_mumbai.default_security_list_id]
}


# ============================================================================
# IPSEC VPN CONNECTION TO AWS (Conditional Creation)
# ============================================================================

# Customer Premises Equipment (represents AWS VPN Gateway)
resource "oci_core_cpe" "aws_vpn_gateway" {
  count = var.create_ipsec ? 1 : 0
  
  compartment_id = var.compartment_id
  ip_address     = var.aws_vpn_gateway_ip
  display_name   = "AWS Customer Premises Equipment"
}

# IPSec Connection
resource "oci_core_ipsec" "oci_to_aws_ipsec" {
  count = var.create_ipsec ? 1 : 0
  
  compartment_id = var.compartment_id
  cpe_id         = oci_core_cpe.aws_vpn_gateway[0].id
  drg_id         = oci_core_drg.oci_drg.id
  display_name   = "IPSec Connection OCI to AWS"
  static_routes  = [var.aws_vpc_cidr]
}

# Fetch IPSec Tunnel Information
data "oci_core_ipsec_connection_tunnels" "ipsec_tunnels" {
  count = var.create_ipsec ? 1 : 0
  
  ipsec_id = oci_core_ipsec.oci_to_aws_ipsec[0].id
}

# Configure Primary IPSec Tunnel
resource "oci_core_ipsec_connection_tunnel_management" "primary_tunnel" {
  count = var.create_ipsec ? 1 : 0
  
  ipsec_id  = oci_core_ipsec.oci_to_aws_ipsec[0].id
  tunnel_id = data.oci_core_ipsec_connection_tunnels.ipsec_tunnels[0].ip_sec_connection_tunnels[0].id

  display_name  = "OCI-to-AWS-Tunnel-1"
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

