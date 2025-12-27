variable "backend_ip" {
  type        = string
  default     = ""
  description = "Backend VM IP Address"
}
variable "compartment_ocid" {
  type        = string
  default     = ""
  description = "OCI Compartment OCID"
}
variable "public_subnet_ocid" {
  type        = string
  default     = ""
  description = "OCI Public Subnet OCID"
}