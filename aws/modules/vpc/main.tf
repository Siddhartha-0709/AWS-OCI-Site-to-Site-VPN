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
# 7. Elastic IP (Stable CGW IP)
################################
resource "aws_eip" "cgw_eip" {
  domain = "vpc"

  tags = {
    Name = "OCI Customer Gateway Elastic IP"
  }
}

output "cgw_eip_ip" {
  value = aws_eip.cgw_eip.public_ip
}

################################
# 8. Customer Gateway (OCI Side)
################################
resource "aws_customer_gateway" "oci_cgw" {
  bgp_asn    = 65000
  ip_address = aws_eip.cgw_eip.public_ip
  type       = "ipsec.1"

  tags = {
    Name = "OCI Customer Gateway"
  }
}

################################
# 9. VPN Connection
################################
resource "aws_vpn_connection" "aws_to_oci" {
  vpn_gateway_id      = aws_vpn_gateway.vgw.id
  customer_gateway_id = aws_customer_gateway.oci_cgw.id
  type                = "ipsec.1"
  static_routes_only  = true

  tags = {
    Name = "AWS to OCI VPN Connection IpSec"
  }
}

################################
# 10. Static Route to OCI
################################
resource "aws_vpn_connection_route" "oci_route" {
  vpn_connection_id      = aws_vpn_connection.aws_to_oci.id
  destination_cidr_block = "10.0.0.0/16"
}

################################
# 11. Outputs (FOR OCI CONFIG)
################################
output "aws_cgw_public_ip" {
  value = aws_eip.cgw_eip.public_ip
}

output "aws_tunnel_1_outside_ip" {
  value = aws_vpn_connection.aws_to_oci.tunnel1_address
}

output "aws_tunnel_2_outside_ip" {
  value = aws_vpn_connection.aws_to_oci.tunnel2_address
}
    
output "private_subnet_id" {
  value = aws_subnet.private_subnet.id
}

output "security_group_id" {
  value = aws_security_group.main_sg.id
}