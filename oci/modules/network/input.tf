# ============================================================================
# VARIABLES
# ============================================================================
variable "compartment_id" {
  description = "OCI Compartment OCID"
  type        = string
}

variable "aws_vpn_gateway_ip" {
  description = "AWS Virtual Private Gateway public IP address (from AWS output)"
  type        = string
  default     = ""  # Empty by default, will be provided after AWS deployment
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

variable "create_ipsec" {
  description = "Set to true to create IPSec connection (after getting AWS tunnel IP)"
  type        = bool
}