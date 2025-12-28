variable "compartment_id" {
  type = string
}

variable "drg_id" {
  type = string
}

variable "aws_tunnel_1_ip" {
  description = "AWS VPN Gateway Tunnel 1 outside IP"
  type        = string
}