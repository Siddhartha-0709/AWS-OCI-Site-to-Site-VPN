module "oci_instance" {
  source                       = "./modules/Instance"
  compartment_id               = "ocid1.compartment.oc1..aaaaaaaaoexx4dnbuigdkqj3rpuqdodbf4jjtgvclm3me7bsp7txhas2cvrq"
  instance_availability_domain = "Uocm:AP-MUMBAI-1-AD-1"
  private_subnet_id            = module.oci_network.private_subnet_id
  depends_on = [ module.oci_network ]
}

module "oci_network" {
  source                 = "./modules/Network"
  compartment_id         = "ocid1.compartment.oc1..aaaaaaaaoexx4dnbuigdkqj3rpuqdodbf4jjtgvclm3me7bsp7txhas2cvrq"
  aws_vpc_cidr           = "192.168.0.0/16"
  oci_vcn_cidr           = "10.0.0.0/16"
  tunnel_1_shared_secret = "qwertyuiopasdfghjkl"
  aws_vpn_gateway_ip     = ""
}