variable "compartment_id" {
  type        = string
  default     = ""
  description = "Enter Compartment ID to Create Resources"
}

variable "private_subnet_id" {
  type        = string
  default     = ""
  description = "OCI Private Subnet OCID"
}

variable "instance_shape" {
  type        = string
  default     = "VM.Standard.E2.1.Micro"
  description = "OCI Instance Shape"
}

variable "image_ocid" {
  type        = string
  default     = "ocid1.image.oc1.ap-mumbai-1.aaaaaaaa3k2zgro5ew3653n5ua26xbql7zh3izfthat4in7lfjjpelezbfwa"
  description = "OCI Instance Image OCID"
}

variable "instance_availability_domain" {
  type        = string
  default     = "Uocm:AP-MUMBAI-1-AD-1"
  description = "OCI Instance Availability Domain"
}

