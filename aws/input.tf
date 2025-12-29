# ============================================================================
# VARIABLES
# ============================================================================

variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "ap-south-1"
}

variable "oci_tunnel_public_ip" {
  description = "OCI IPSec Tunnel Public IP (use 1.1.1.1 initially)"
  type        = string
}

variable "tunnel_1_shared_secret" {
  description = "Shared secret for IPSec Tunnel 1"
  type        = string
  sensitive   = true
  default     = "qwertyuiopasdfghjkl"
}