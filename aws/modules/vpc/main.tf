# ============================================================================
# VARIABLES
# ============================================================================
variable "oci_tunnel_public_ip" {
  description = "OCI IPSec Tunnel Public IP (from OCI output)"
  type        = string
  default     = "1.1.1.1"  # Placeholder - update after OCI provisioning
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

# ============================================================================
# VPC AND NETWORKING RESOURCES
# ============================================================================
resource "aws_vpc" "vpc_aws_mumbai" {
  cidr_block           = var.aws_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "VPC-AWS-Mumbai"
  }
}

# ============================================================================
# SUBNETS
# ============================================================================
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.vpc_aws_mumbai.id
  cidr_block              = "192.168.0.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Subnet-Public"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.vpc_aws_mumbai.id
  cidr_block        = "192.168.1.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "Subnet-Private"
  }
}

# ============================================================================
# INTERNET GATEWAY
# ============================================================================
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc_aws_mumbai.id

  tags = {
    Name = "IGW-AWS-Mumbai"
  }
}

# ============================================================================
# VIRTUAL PRIVATE GATEWAY (VGW)
# ============================================================================
resource "aws_vpn_gateway" "vgw" {
  vpc_id = aws_vpc.vpc_aws_mumbai.id

  tags = {
    Name = "VGW-AWS-Mumbai"
  }
}

# Enable route propagation for VGW
resource "aws_vpn_gateway_route_propagation" "private_propagation" {
  vpn_gateway_id = aws_vpn_gateway.vgw.id
  route_table_id = aws_route_table.private_rt.id
}

# ============================================================================
# ROUTE TABLES
# ============================================================================
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc_aws_mumbai.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "RT-Public-Subnet"
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.vpc_aws_mumbai.id

  route {
    cidr_block = var.oci_vcn_cidr
    gateway_id = aws_vpn_gateway.vgw.id
  }

  tags = {
    Name = "RT-Private-Subnet"
  }
}

resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_rt.id
}

# ============================================================================
# SECURITY GROUP
# ============================================================================
resource "aws_security_group" "main_sg" {
  vpc_id      = aws_vpc.vpc_aws_mumbai.id
  name        = "SG-AWS-Mumbai-Main"
  description = "Security group for AWS Mumbai VPC"

  # Allow all traffic from OCI VCN
  ingress {
    description = "All traffic from OCI VCN"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = [var.oci_vcn_cidr]
  }

  # Allow SSH from anywhere (adjust as needed)
  ingress {
    description = "SSH from anywhere"
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow ICMP for testing
  ingress {
    description = "ICMP from anywhere"
    protocol    = "icmp"
    from_port   = -1
    to_port     = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound
  egress {
    description = "All outbound traffic"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SG-AWS-Mumbai-Main"
  }
}

# ============================================================================
# CUSTOMER GATEWAY (Represents OCI IPSec Tunnel Endpoint)
# ============================================================================
resource "aws_customer_gateway" "oci_cgw" {
  bgp_asn    = 65000
  ip_address = var.oci_tunnel_public_ip
  type       = "ipsec.1"

  tags = {
    Name = "CGW-OCI-Mumbai"
  }
}

# ============================================================================
# SITE-TO-SITE VPN CONNECTION
# ============================================================================
resource "aws_vpn_connection" "aws_to_oci_vpn" {
  vpn_gateway_id      = aws_vpn_gateway.vgw.id
  customer_gateway_id = aws_customer_gateway.oci_cgw.id
  type                = "ipsec.1"
  static_routes_only  = true

  # Tunnel 1 Configuration
  tunnel1_inside_cidr   = "169.254.10.0/30"
  tunnel1_preshared_key = var.tunnel_1_shared_secret

  # IKE Configuration
  tunnel1_ike_versions   = ["ikev2"]
  tunnel1_startup_action = "start"

  # Dead Peer Detection
  tunnel1_dpd_timeout_action  = "restart"
  tunnel1_dpd_timeout_seconds = 30

  # Phase 1 (IKE) Parameters
  tunnel1_phase1_dh_group_numbers = [14]
  tunnel1_phase1_lifetime_seconds = 28800

  # Phase 2 (IPSec) Parameters
  tunnel1_phase2_dh_group_numbers = [14]
  tunnel1_phase2_lifetime_seconds = 3600

  tags = {
    Name = "VPN-AWS-to-OCI"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================================================
# STATIC ROUTE TO OCI VCN
# ============================================================================
resource "aws_vpn_connection_route" "oci_route" {
  vpn_connection_id      = aws_vpn_connection.aws_to_oci_vpn.id
  destination_cidr_block = var.oci_vcn_cidr
}

# ============================================================================
# OUTPUTS
# ============================================================================

# VPC Outputs
output "vpc_id" {
  value       = aws_vpc.vpc_aws_mumbai.id
  description = "AWS VPC ID"
}

output "vpc_cidr" {
  value       = aws_vpc.vpc_aws_mumbai.cidr_block
  description = "AWS VPC CIDR block"
}

# Subnet Outputs
output "public_subnet_id" {
  value       = aws_subnet.public_subnet.id
  description = "Public Subnet ID"
}

output "private_subnet_id" {
  value       = aws_subnet.private_subnet.id
  description = "Private Subnet ID"
}

# Security Group
output "security_group_id" {
  value       = aws_security_group.main_sg.id
  description = "Main Security Group ID"
}

# VPN Gateway
output "vpn_gateway_id" {
  value       = aws_vpn_gateway.vgw.id
  description = "Virtual Private Gateway ID"
}

# Customer Gateway
output "customer_gateway_id" {
  value       = aws_customer_gateway.oci_cgw.id
  description = "Customer Gateway ID"
}

# VPN Connection
output "vpn_connection_id" {
  value       = aws_vpn_connection.aws_to_oci_vpn.id
  description = "Site-to-Site VPN Connection ID"
}

# AWS Tunnel Endpoints (Use this as CPE IP in OCI)
output "aws_tunnel_1_public_ip" {
  value       = aws_vpn_connection.aws_to_oci_vpn.tunnel1_address
  description = "AWS VPN Tunnel 1 public IP - Use this as CPE IP address in OCI"
}

output "aws_tunnel_1_status" {
  value       = aws_vpn_connection.aws_to_oci_vpn.tunnel1_status
  description = "AWS Tunnel 1 connection status"
}

output "aws_tunnel_1_inside_cidr" {
  value       = aws_vpn_connection.aws_to_oci_vpn.tunnel1_inside_cidr
  description = "AWS Tunnel 1 inside CIDR (for BGP if needed)"
}

# Sensitive outputs
output "tunnel_1_preshared_key" {
  value       = aws_vpn_connection.aws_to_oci_vpn.tunnel1_preshared_key
  description = "Tunnel 1 pre-shared key"
  sensitive   = true
}

# ============================================================================
# DEPLOYMENT INSTRUCTIONS
# ============================================================================
# 
# STEP-BY-STEP DEPLOYMENT:
# 
# 1. INITIAL DEPLOYMENT (with placeholder):
#    terraform apply -var="oci_tunnel_public_ip=1.1.1.1"
#    
#    This creates AWS VPN with placeholder Customer Gateway
#    Note: VPN will be in "DOWN" state - this is expected
#
# 2. GET AWS TUNNEL IP:
#    terraform output aws_tunnel_1_public_ip
#    
#    Copy this IP address
#
# 3. DEPLOY OCI INFRASTRUCTURE:
#    Update OCI terraform with:
#    - aws_vpn_gateway_ip = <aws_tunnel_1_public_ip from step 2>
#    - tunnel_1_shared_secret = "qwertyuiopasdfghjkl"
#    
#    terraform apply (on OCI side)
#
# 4. GET OCI TUNNEL IP:
#    terraform output oci_vpn_tunnel_public_ip (from OCI)
#    
#    Copy this IP address
#
# 5. UPDATE AWS WITH REAL OCI IP:
#    terraform apply -var="oci_tunnel_public_ip=<oci_vpn_tunnel_public_ip>"
#    
#    This will:
#    - Update the Customer Gateway with real OCI IP
#    - Recreate the VPN connection (AWS requirement)
#    - Establish the tunnel connection
#
# 6. VERIFY CONNECTION:
#    Check tunnel status:
#    - AWS Console: VPC → Site-to-Site VPN Connections
#    - OCI Console: Networking → IPSec Connections
#    
#    Both sides should show "UP" status
#
# 7. TEST CONNECTIVITY:
#    - Launch EC2 instance in private subnet
#    - Launch OCI compute instance in private subnet  
#    - Test ping between instances using private IPs
#
# ============================================================================