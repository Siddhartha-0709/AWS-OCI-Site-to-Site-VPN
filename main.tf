variable "oci_cpe_public_ip" {
  description = "OCI IPSec tunnel public IP"
  type        = string
  # default     = "1.1.1.1"
}

variable "aws_tunnel_1_outside_ip" {
  description = "AWS VPN tunnel 1 outside IP"
  type        = string
  # default     = "1.1.1.1"
}

module "aws" {
  source = "./aws"
  
  oci_cpe_public_ip = var.oci_cpe_public_ip
}

module "oci" {
  source = "./oci"
  
  aws_tunnel_1_outside_ip = var.aws_tunnel_1_outside_ip
}

# Outputs
output "STEP_1_AWS_TUNNEL_IP" {
  description = "Use this IP in OCI CPE"
  value       = module.aws.aws_tunnel_1_outside_ip
}

output "STEP_2_OCI_TUNNEL_IP" {
  description = "Use this IP to update AWS Customer Gateway"
  value       = module.oci.oci_tunnel_1_public_ip
}

output "aws_ec2_private_ip" {
  value = module.aws.aws_ec2_instance_private_ip
}