resource "oci_core_vcn" "vcn_oci_mumbai" {
    compartment_id = var.compartment_id
    cidr_block     = "10.0.0.0/16"
    display_name   = "VCN OCI Mumbai"
}

resource "oci_core_internet_gateway" "internet_gateway" {
    compartment_id = var.compartment_id
    vcn_id         = oci_core_vcn.vcn_oci_mumbai.id
    display_name   = "Internet Gateway"
}

resource "oci_core_route_table" "public_route_table" {
    compartment_id = var.compartment_id
    vcn_id         = oci_core_vcn.vcn_oci_mumbai.id
    display_name   = "Public Route Table"

   route_rules {
        destination       = "0.0.0.0/0"
        destination_type  = "CIDR_BLOCK"
        network_entity_id = oci_core_internet_gateway.internet_gateway.id
    }
}

resource "oci_core_route_table" "private_route_table" {
    compartment_id = var.compartment_id
    vcn_id         = oci_core_vcn.vcn_oci_mumbai.id
    display_name   = "Private Route Table"

    route_rules {
        destination       = "192.168.0.0/16"
        destination_type  = "CIDR_BLOCK"
        network_entity_id = var.drg_id
    }

}

resource "oci_core_subnet" "public_subnet" {
    compartment_id      = var.compartment_id
    vcn_id              = oci_core_vcn.vcn_oci_mumbai.id
    cidr_block          = "10.0.0.0/24"
    display_name        = "Public Subnet"
    route_table_id      = oci_core_route_table.public_route_table.id
}

resource "oci_core_subnet" "private_subnet" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn_oci_mumbai.id
  cidr_block     = "10.0.1.0/24"
  display_name   = "Private Subnet"
  route_table_id = oci_core_route_table.private_route_table.id
  prohibit_public_ip_on_vnic = true
}


output vcn_id {
  value       = oci_core_vcn.vcn_oci_mumbai.id
  sensitive   = true
  description = "The OCID of the Virtual Cloud Network"
  depends_on  = []
}
output private_subnet_id {
  value       = oci_core_subnet.private_subnet.id
  sensitive   = true
  description = "The OCID of the Private Subnet"
  depends_on  = []
}

output public_subnet_id {
  value       = oci_core_subnet.public_subnet.id
  sensitive   = true
  description = "The OCID of the Public Subnet"
  depends_on  = []
}