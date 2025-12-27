resource "oci_load_balancer_load_balancer" "public_loadbalancer" {
  compartment_id = var.compartment_ocid
  display_name   = "Public Load Balancer"
  shape          = "flexible"

  shape_details {
    minimum_bandwidth_in_mbps = 10
    maximum_bandwidth_in_mbps = 10
  }

  subnet_ids = [
    var.public_subnet_ocid
  ]

  is_private = false
}

resource "oci_load_balancer_backend_set" "vm_1_backend_set_ssh" {
  load_balancer_id = oci_load_balancer_load_balancer.public_loadbalancer.id
  name             = "VM-1-Backend-Set-SSH"

  policy = "ROUND_ROBIN"

  health_checker {
    protocol = "TCP"
    url_path = "/"
    port     = 22
    timeout_in_millis  = 3000
  }
}

resource "oci_load_balancer_backend" "vm_1_backend_ssh" {
  load_balancer_id = oci_load_balancer_load_balancer.public_loadbalancer.id
  backendset_name = oci_load_balancer_backend_set.vm_1_backend_set_ssh.name

  ip_address = var.backend_ip
  port       = 22
  weight     = 1
}

resource "oci_load_balancer_listener" "ssh_listener_vm_1" {
  load_balancer_id         = oci_load_balancer_load_balancer.public_loadbalancer.id
  name                     = "ssh_listener_vm_1"
  default_backend_set_name = oci_load_balancer_backend_set.vm_1_backend_set_ssh.name
  port                     = 22
  protocol                 = "TCP"
}
