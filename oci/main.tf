# ============================================================================
# NETWORK MODULE
# ============================================================================
module "oci_network" {
  source = "./modules/network"

  compartment_id         = var.compartment_id
  aws_vpn_gateway_ip     = var.aws_vpn_gateway_ip
  create_ipsec           = var.create_ipsec
  tunnel_1_shared_secret = var.tunnel_1_shared_secret
  aws_vpc_cidr           = "192.168.0.0/16"
  oci_vcn_cidr           = "10.0.0.0/16"
}

# ============================================================================
# COMPUTE MODULE
# ============================================================================

module "oci_instance" {
  source                       = "./modules/compute"

  compartment_id               =  var.compartment_id
  private_subnet_id            = module.oci_network.private_subnet_id
  depends_on                   = [ module.oci_network ]
}

# ############################################################################
# LOAD BALANCER MODULE
# ############################################################################

module "oci_load_balancer" {
  source = "./modules/loadbalancer"

  compartment_ocid = "ocid1.compartment.oc1..aaaaaaaaoexx4dnbuigdkqj3rpuqdodbf4jjtgvclm3me7bsp7txhas2cvrq"
  backend_ip_vm1       = module.oci_instance.app_instance_private_ip_1
  backend_ip_vm2       = module.oci_instance.app_instance_private_ip_2
  subnet_ocid      = module.oci_network.public_subnet_id
  depends_on       =  [ module.oci_instance, module.oci_network ]
}
