# ============================================================================
# VARIABLES
# ============================================================================
variable "oci_region" {
  description = "OCI Region"
  type        = string
  default     = "ap-mumbai-1"
}

variable "compartment_id" {
  description = "OCI Compartment OCID"
  type        = string
  default     = "ocid1.compartment.oc1..aaaaaaaaoexx4dnbuigdkqj3rpuqdodbf4jjtgvclm3me7bsp7txhas2cvrq"
}

variable "aws_vpn_gateway_ip" {
  description = "AWS VPN Gateway public IP (from AWS terraform output)"
  type        = string
  default     = ""
}

variable "create_ipsec" {
  description = "Set to true to create IPSec connection (after AWS is deployed)"
  type        = bool
  default     = false
}

variable "tunnel_1_shared_secret" {
  description = "Shared secret for IPSec Tunnel 1"
  type        = string
  sensitive   = true
  default     = "qwertyuiopasdfghjkl"
}
