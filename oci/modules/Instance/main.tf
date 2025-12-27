resource "oci_core_instance" "app_instance" {
  availability_domain = "LoLm:AP-MUMBAI-1-AD-1"
  compartment_id      = var.compartment_id
  shape               = "VM.Standard.E2.1.Micro"
  display_name        = "App Instance - 1"

  create_vnic_details {
    subnet_id        = var.private_subnet_id
    assign_public_ip = false
  }

  metadata = {
    ssh_authorized_keys = file("/home/ubuntu/aws-oci-terraform-project/oci/keyFile/keyfile.pub")
  }

  source_details {
    source_type = "image"
    source_id   = "ocid1.image.oc1.ap-mumbai-1.aaaaaaaabdnvaownbvzsjbucdgnfjdw2phl3fzspv4rgy5y65iwsxme2z6ya"
  }
}




output "app_instance_1_private_ip" {
  value       = oci_core_instance.app_instance.private_ip
  sensitive   = true
  description = "Private IP address of the app instance"
  depends_on  = []
}
