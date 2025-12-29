resource "oci_core_instance" "app_instance1" {
  compartment_id      = var.compartment_id
  shape               = "VM.Standard.E2.1.Micro"
  display_name        = "Application VM - 1"
  availability_domain = "Lolm:AP-MUMBAI-1-AD-1"

  create_vnic_details {
    subnet_id        = var.private_subnet_id
    assign_public_ip = false
  }

  metadata = {
    ssh_authorized_keys = file("/home/ubuntu/aws-oci-terraform-project/oci/keyFile/keyfile.pub")
  }

  source_details {
    source_type = "image"
    source_id   = "ocid1.image.oc1.ap-mumbai-1.aaaaaaaa3k2zgro5ew3653n5ua26xbql7zh3izfthat4in7lfjjpelezbfwa"
  }
}



resource "oci_core_instance" "app_instance2" {
  compartment_id      = var.compartment_id
  shape               = "VM.Standard.E2.1.Micro"
  display_name        = "Application VM - 2"
  availability_domain = "Lolm:AP-MUMBAI-1-AD-1"

  create_vnic_details {
    subnet_id        = var.private_subnet_id
    assign_public_ip = false
  }

  metadata = {
    ssh_authorized_keys = file("/home/ubuntu/aws-oci-terraform-project/oci/keyFile/keyfile.pub")
  }

  source_details {
    source_type = "image"
    source_id   = "ocid1.image.oc1.ap-mumbai-1.aaaaaaaa3k2zgro5ew3653n5ua26xbql7zh3izfthat4in7lfjjpelezbfwa"
  }
}
