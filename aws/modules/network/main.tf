# ============================================================================
# VPC AND NETWORKING RESOURCES
# ============================================================================
resource "aws_vpc" "vpc_aws_mumbai" {
  cidr_block           = var.aws_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "Database VPC AWS Mumbai"
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
    Name = "Public Subnet AWS Mumbai"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.vpc_aws_mumbai.id
  cidr_block        = "192.168.1.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "Private Subnet AWS Mumbai"
  }
}

# ============================================================================
# INTERNET GATEWAY
# ============================================================================
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc_aws_mumbai.id

  tags = {
    Name = "Internet Gateway AWS Mumbai"
  }
}

# ============================================================================
# VIRTUAL PRIVATE GATEWAY (VGW)
# ============================================================================
resource "aws_vpn_gateway" "vgw" {
  vpc_id = aws_vpc.vpc_aws_mumbai.id

  tags = {
    Name = "Virtual Private Gateway AWS Mumbai"
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
    Name = "Public Subnet Route Table"
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
    Name = "Private Subnet Route Table"
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
  name        = "Main Security Group AWS Mumbai"
  description = "Security group for AWS Mumbai VPC allowing all necessary traffic"

  # Allow all traffic from OCI VCN
  ingress {
    description = "All traffic"
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
    Name = "Main Security Group AWS Mumbai"
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
    Name = "OCI Customer Gateway"
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
    Name = "IpSec VPN Connection AWS to OCI"
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
