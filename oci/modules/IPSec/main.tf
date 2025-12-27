# 1. Customer Premises Equipment (AWS VPN) in OCI
resource "oci_core_cpe" "aws_cpe" {
  display_name = "AWS-CPE"
  compartment_id = var.compartment_id
  ip_address     = var.aws_tunnel_1_ip # pass from AWS output
}

# 2. IPSec Connection
resource "oci_core_ipsec_connection" "aws_to_oci" {
  compartment_id = var.compartment_id
  cpe_id         = oci_core_cpe.aws_cpe.id
  drg_id         = oci_core_drg.drg.id
  display_name   = "AWS to OCI IPSec"

  static_routes = ["192.168.0.0/16"] # AWS VPC

  # Optional: phase1/phase2 parameters if needed
  depends_on = [aws_vpn_connection.aws_to_oci]  # wait for AWS VPN
}
# 3. Outputs
output "oci_ipsec_id" {
  value = oci_core_ipsec_connection.aws_to_oci.id
}