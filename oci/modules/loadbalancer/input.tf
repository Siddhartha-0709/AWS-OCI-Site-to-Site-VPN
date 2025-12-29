# ============================================================================
# VARIABLES
# ============================================================================
variable "compartment_ocid" {
  description = "OCI Compartment OCID"
  type        = string
}

variable "subnet_ocid" {
  description = "OCI Subnet OCID where Load Balancer will be created"
  type        = string
}

variable "backend_ip_vm1" {
  description = "Backend IP Address of VM 1"
  type = string
}

variable "backend_ip_vm2" {
  description = "Backend IP Address of VM 2"
  type = string
}
