module "oci_drg" {
  source = "./modules/DRG"
  compartment_id = "ocid1.compartment.oc1..aaaaaaaaoexx4dnbuigdkqj3rpuqdodbf4jjtgvclm3me7bsp7txhas2cvrq"
}

module "oci_network" {
  source = "./modules/VCN"
  compartment_id = "ocid1.compartment.oc1..aaaaaaaaoexx4dnbuigdkqj3rpuqdodbf4jjtgvclm3me7bsp7txhas2cvrq"
  drg_id = module.oci_drg.drg_id
}

module "drg_vcn_attachment" {
  source = "./modules/DRG-VCN-Attachments"
  drg_id = module.oci_drg.drg_id
  vcn_id = module.oci_network.vcn_id
}

module "oci_instance" {
  source = "./modules/Instance"
  compartment_id = "ocid1.compartment.oc1..aaaaaaaaoexx4dnbuigdkqj3rpuqdodbf4jjtgvclm3me7bsp7txhas2cvrq"
  instance_availability_domain = "Uocm:AP-MUMBAI-1-AD-1"
  private_subnet_id = module.oci_network.private_subnet_id
}


module "oci_loadbalancer" {
  source = "./modules/Loadbalancer"
  compartment_ocid = "ocid1.compartment.oc1..aaaaaaaaoexx4dnbuigdkqj3rpuqdodbf4jjtgvclm3me7bsp7txhas2cvrq"
  public_subnet_ocid = module.oci_network.public_subnet_id
  backend_ip = module.oci_instance.app_instance_1_private_ip
}


module "oci_ipsec" {
  source = "./modules/IPSec"
  compartment_id = "ocid1.compartment.oc1..aaaaaaaaoexx4dnbuigdkqj3rpuqdodbf4jjtgvclm3me7bsp7txhas2cvrq"
  drg_id = module.oci_drg.drg_id
  aws_tunnel_1_ip = var.aws_tunnel_1_outside_ip
}