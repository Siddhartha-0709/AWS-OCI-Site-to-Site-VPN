################################
# INPUT VARIABLES
################################
variable "oci_cpe_public_ip" {
  description = "OCI IPSec Tunnel Public IP (use 1.1.1.1 initially, then update with real OCI tunnel IP)"
  type        = string
  default     = "1.1.1.1"
}

variable "use_real_cgw" {
  description = "Set to true to switch from temp CGW to real CGW (after OCI is configured)"
  type        = bool
  default     = false
}

################################
# 1. VPC
################################
resource "aws_vpc" "main" {
  cidr_block           = "192.168.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "AWS Mumbai VPC"
  }
}

################################
# 2. Subnets
################################
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "192.168.0.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public Subnet"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "192.168.1.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "Private Subnet"
  }
}

################################
# 3. Internet Gateway
################################
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Internet Gateway"
  }
}

################################
# 4. Route Tables
################################
# Public RT
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Public Route Table"
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# Private RT (OCI traffic → VPN)
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "10.0.0.0/16" # OCI VCN
    gateway_id = aws_vpn_gateway.vgw.id
  }

  tags = {
    Name = "Private Route Table"
  }
}

resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_rt.id
}

################################
# 5. Security Group
################################
resource "aws_security_group" "main_sg" {
  vpc_id = aws_vpc.main.id
  name   = "AWS Mumbai VPC Security Group"

  ingress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

################################
# 6. VPN Gateway (VGW)
################################
resource "aws_vpn_gateway" "vgw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "VPN Gateway AWS Mumbai"
  }
}

################################
# 7. Customer Gateways - TWO GATEWAYS APPROACH
################################

# Temporary Customer Gateway (placeholder) - Used initially
resource "aws_customer_gateway" "oci_cgw_temp" {
  bgp_asn    = 65000
  ip_address = "1.1.1.1"
  type       = "ipsec.1"
  
  tags = {
    Name = "OCI Customer Gateway (Temporary)"
  }
}

# Real Customer Gateway - Starts with 1.1.1.1, then updated to real OCI IP
resource "aws_customer_gateway" "oci_cgw_real" {
  bgp_asn    = 65000
  ip_address = var.oci_cpe_public_ip
  type       = "ipsec.1"
  
  tags = {
    Name = "OCI Customer Gateway (Production)"
  }
}

################################
# 8. VPN Connection with Tunnel Configuration
# Initially uses temp CGW, then switches to real CGW
################################
resource "aws_vpn_connection" "aws_to_oci" {
  vpn_gateway_id      = aws_vpn_gateway.vgw.id
  customer_gateway_id = var.use_real_cgw ? aws_customer_gateway.oci_cgw_real.id : aws_customer_gateway.oci_cgw_temp.id
  type                = "ipsec.1"
  static_routes_only  = true

  # Tunnel 1 Configuration (IKEv2 for OCI)
  tunnel1_inside_cidr   = "169.254.10.0/30"
  tunnel1_preshared_key = "qwertyuiopasdfghjklzxcvbnm"
  
  tunnel1_ike_versions                 = ["ikev2"]
  tunnel1_startup_action               = "start"
  tunnel1_dpd_timeout_action           = "restart"
  tunnel1_dpd_timeout_seconds          = 30
  
  # Phase 1 (IKE) Configuration
  # tunnel1_phase1_encryption_algorithms = ["AES256"]
  # tunnel1_phase1_integrity_algorithms  = ["SHA256"]
  tunnel1_phase1_dh_group_numbers      = [14]
  tunnel1_phase1_lifetime_seconds      = 28800
  
  # Phase 2 (IPSec) Configuration
  # tunnel1_phase2_encryption_algorithms = ["AES256"]
  # tunnel1_phase2_integrity_algorithms  = ["SHA256"]
  tunnel1_phase2_dh_group_numbers      = [14]
  tunnel1_phase2_lifetime_seconds      = 3600




  # Tunnel 2 Configuration (Optional backup)
  # tunnel2_inside_cidr   = "169.254.11.0/30"
  # tunnel2_preshared_key = "qwertyuiopasdfghjklzxcvbnm"
  
  # tunnel2_ike_versions                 = ["ikev2"]
  # tunnel2_startup_action               = "start"
  # tunnel2_dpd_timeout_action           = "restart"
  # tunnel2_dpd_timeout_seconds          = 30
  
  # tunnel2_phase1_encryption_algorithms = ["AES256"]
  # tunnel2_phase1_integrity_algorithms  = ["SHA256"]
  # tunnel2_phase1_dh_group_numbers      = [14]
  # tunnel2_phase1_lifetime_seconds      = 28800
  
  # tunnel2_phase2_encryption_algorithms = ["AES256"]
  # tunnel2_phase2_integrity_algorithms  = ["SHA256"]
  # tunnel2_phase2_dh_group_numbers      = [14]
  # tunnel2_phase2_lifetime_seconds      = 3600

  tags = {
    Name = "AWS to OCI VPN Connection IpSec"
  }

  lifecycle {
    create_before_destroy = true
  }
}

################################
# 9. Static Route to OCI
################################
resource "aws_vpn_connection_route" "oci_route" {
  vpn_connection_id      = aws_vpn_connection.aws_to_oci.id
  destination_cidr_block = "10.0.0.0/16"
}

################################
# 10. Outputs (FOR OCI CONFIG)
################################
output "aws_tunnel_1_outside_ip" {
  description = "AWS VPN Tunnel 1 Outside IP - Use this in OCI CPE"
  value       = aws_vpn_connection.aws_to_oci.tunnel1_address
}

output "aws_tunnel_2_outside_ip" {
  description = "AWS VPN Tunnel 2 Outside IP - Use this in OCI CPE (optional)"
  value       = aws_vpn_connection.aws_to_oci.tunnel2_address
}

output "aws_tunnel_1_preshared_key" {
  description = "Tunnel 1 Pre-shared Key"
  value       = aws_vpn_connection.aws_to_oci.tunnel1_preshared_key
  sensitive   = true
}

output "aws_tunnel_2_preshared_key" {
  description = "Tunnel 2 Pre-shared Key"
  value       = aws_vpn_connection.aws_to_oci.tunnel2_preshared_key
  sensitive   = true
}

output "aws_vpn_connection_id" {
  description = "VPN Connection ID"
  value       = aws_vpn_connection.aws_to_oci.id
}

output "temp_cgw_id" {
  description = "Temporary Customer Gateway ID (delete after migration)"
  value       = aws_customer_gateway.oci_cgw_temp.id
}

output "real_cgw_id" {
  description = "Real Customer Gateway ID"
  value       = aws_customer_gateway.oci_cgw_real.id
}
    
output "private_subnet_id" {
  value = aws_subnet.private_subnet.id
}

output "security_group_id" {
  value = aws_security_group.main_sg.id
}

