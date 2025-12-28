# ./oci/modules/IPSec/main.tf

################################
# 1. Customer Premises Equipment (AWS VPN) in OCI
################################
resource "oci_core_cpe" "aws_cpe" {
  display_name   = "AWS-CPE"
  compartment_id = var.compartment_id
  ip_address     = var.aws_tunnel_1_ip 
  
  # cpe_device_shape_id = data.oci_core_cpe_device_shapes.aws_shapes.cpe_device_shapes[0].cpe_device_shape_id
}

# Get AWS CPE device shape
# data "oci_core_cpe_device_shapes" "aws_shapes" {
#   filter {
#     name   = "cpe_device_info"
#     values = [".*AWS.*"]
#     regex  = true
#   }
# }

################################
# 2. IPSec Connection
################################
resource "oci_core_ipsec" "aws_to_oci" {
  compartment_id = var.compartment_id
  cpe_id         = oci_core_cpe.aws_cpe.id
  drg_id         = var.drg_id
  display_name   = "AWS to OCI IPSec"

  static_routes = ["192.168.0.0/16"] # AWS VPC CIDR
}

################################
# 3. Data Source to Fetch Tunnel Information
################################
data "oci_core_ipsec_connection_tunnels" "aws_tunnels" {
  ipsec_id = oci_core_ipsec.aws_to_oci.id
}

################################
# 4. Configure Tunnel 1 with IKEv2 and matching parameters
################################
resource "oci_core_ipsec_connection_tunnel_management" "tunnel_1" {
  ipsec_id  = oci_core_ipsec.aws_to_oci.id
  tunnel_id = data.oci_core_ipsec_connection_tunnels.aws_tunnels.ip_sec_connection_tunnels[0].id

  routing = "STATIC"
  
  ike_version = "V2"
  
  shared_secret = "qwertyuiopasdfghjklzxcvbnm"
  
  display_name = "Tunnel 1 to AWS"

  # Phase 1 (IKE) Configuration - Match AWS settings
  encryption_domain_config {
    oracle_traffic_selector  = ["10.0.0.0/16"]  # OCI VCN CIDR
    cpe_traffic_selector     = ["192.168.0.0/16"] # AWS VPC CIDR
  }

  # BGP Session Config (not used for static, but required)
  # bgp_session_config {
  #   customer_bgp_asn      = "65000"
  #   customer_interface_ip = "169.254.10.2/30"
  #   oracle_interface_ip   = "169.254.10.1/30"
  # }

  # DPD Configuration
  dpd_config {
    dpd_mode             = "RESPOND_ONLY"
    dpd_timeout_in_sec   = 30
  }
}

################################
# 5. Optional: Configure Tunnel 2
################################
resource "oci_core_ipsec_connection_tunnel_management" "tunnel_2" {
  ipsec_id  = oci_core_ipsec.aws_to_oci.id
  tunnel_id = data.oci_core_ipsec_connection_tunnels.aws_tunnels.ip_sec_connection_tunnels[1].id

  routing = "STATIC"
  
  ike_version = "V2"
  
  shared_secret = "qwertyuiopasdfghjklzxcvbnm"
  
  display_name = "Tunnel 2 to AWS (Backup)"

  encryption_domain_config {
    oracle_traffic_selector  = ["10.0.0.0/16"]
    cpe_traffic_selector     = ["192.168.0.0/16"]
  }

  # bgp_session_config {
  #   customer_bgp_asn      = "65000"
  #   customer_interface_ip = "169.254.11.2/30"
  #   oracle_interface_ip   = "169.254.11.1/30"
  # }

  dpd_config {
    dpd_mode             = "RESPOND_ONLY"
    dpd_timeout_in_sec   = 30
  }
}

################################
# 6. Outputs - OCI IPSec Tunnel Public IPs
################################
output "oci_ipsec_id" {
  description = "OCI IPSec Connection ID"
  value       = oci_core_ipsec.aws_to_oci.id
}

output "oci_tunnel_1_public_ip" {
  description = "OCI Tunnel 1 Public IP - Use this in AWS Customer Gateway"
  value       = data.oci_core_ipsec_connection_tunnels.aws_tunnels.ip_sec_connection_tunnels[0].vpn_ip
}

output "oci_tunnel_2_public_ip" {
  description = "OCI Tunnel 2 Public IP (optional backup)"
  value       = data.oci_core_ipsec_connection_tunnels.aws_tunnels.ip_sec_connection_tunnels[1].vpn_ip
}

output "oci_tunnel_1_status" {
  description = "OCI Tunnel 1 Status"
  value       = data.oci_core_ipsec_connection_tunnels.aws_tunnels.ip_sec_connection_tunnels[0].status
}

output "oci_tunnel_2_status" {
  description = "OCI Tunnel 2 Status"
  value       = data.oci_core_ipsec_connection_tunnels.aws_tunnels.ip_sec_connection_tunnels[1].status
}