variable subnet_id {
  type        = string
  default     = ""
  description = "Enter the Subnet ID for Placing the VM"
}

variable security_group_id {
  type        = list(string)
  default     = []
  description = "Enter the Security Group ID for the VM"
}
