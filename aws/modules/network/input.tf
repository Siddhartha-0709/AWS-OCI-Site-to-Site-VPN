# ============================================================================
# VARIABLES
# ============================================================================

variable "oci_tunnel_public_ip" {
  description = "OCI IPSec Tunnel Public IP (from OCI output)"
  type        = string
  # default     = "1.1.1.1"  # Placeholder - update after OCI provisioning
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "ap-south-1"
}

variable "aws_vpc_cidr" {
  description = "AWS VPC CIDR block"
  type        = string
  default     = "192.168.0.0/16"
}

variable "oci_vcn_cidr" {
  description = "OCI VCN CIDR block (for routing)"
  type        = string
  default     = "10.0.0.0/16"
}

variable "tunnel_1_shared_secret" {
  description = "Shared secret for IPSec Tunnel 1"
  type        = string
  sensitive   = true
  default     = "qwertyuiopasdfghjkl"
}