

# ============================================================================
# PUBLIC LOAD BALANCER
# ============================================================================
resource "oci_load_balancer_load_balancer" "public_lb" {
  compartment_id = var.compartment_ocid
  display_name   = "public-load-balancer"
  shape          = "flexible"

  shape_details {
    minimum_bandwidth_in_mbps = 10
    maximum_bandwidth_in_mbps = 10
  }

  subnet_ids = [var.subnet_ocid]
  is_private = false
}

# ============================================================================
# SSH -> VM1 (Port 22)
# ============================================================================
resource "oci_load_balancer_backend_set" "ssh_vm1_bs" {
  load_balancer_id = oci_load_balancer_load_balancer.public_lb.id
  name             = "ssh-vm1-bs"
  policy           = "ROUND_ROBIN"

  health_checker {
    protocol = "TCP"
    port     = 22
  }
}

resource "oci_load_balancer_backend" "ssh_vm1_backend" {
  load_balancer_id = oci_load_balancer_load_balancer.public_lb.id
  backendset_name  = oci_load_balancer_backend_set.ssh_vm1_bs.name
  ip_address       = var.backend_ip_vm1
  port             = 22
  weight           = 1
}

resource "oci_load_balancer_listener" "ssh_vm1_listener" {
  load_balancer_id         = oci_load_balancer_load_balancer.public_lb.id
  name                     = "ssh-vm1-listener"
  port                     = 22
  protocol                 = "TCP"
  default_backend_set_name = oci_load_balancer_backend_set.ssh_vm1_bs.name
}

# ============================================================================
# SSH -> VM2 (Port 23)
# ============================================================================
resource "oci_load_balancer_backend_set" "ssh_vm2_bs" {
  load_balancer_id = oci_load_balancer_load_balancer.public_lb.id
  name             = "ssh-vm2-bs"
  policy           = "ROUND_ROBIN"

  health_checker {
    protocol = "TCP"
    port     = 22
  }
}

resource "oci_load_balancer_backend" "ssh_vm2_backend" {
  load_balancer_id = oci_load_balancer_load_balancer.public_lb.id
  backendset_name  = oci_load_balancer_backend_set.ssh_vm2_bs.name
  ip_address       = var.backend_ip_vm2
  port             = 22
  weight           = 1
}

resource "oci_load_balancer_listener" "ssh_vm2_listener" {
  load_balancer_id         = oci_load_balancer_load_balancer.public_lb.id
  name                     = "ssh-vm2-listener"
  port                     = 23
  protocol                 = "TCP"
  default_backend_set_name = oci_load_balancer_backend_set.ssh_vm2_bs.name
}

# ============================================================================
# HTTP -> VM1 + VM2 (Port 80, Load Balanced)
# ============================================================================
resource "oci_load_balancer_backend_set" "http_bs" {
  load_balancer_id = oci_load_balancer_load_balancer.public_lb.id
  name             = "http-bs"
  policy           = "ROUND_ROBIN"

  health_checker {
    protocol = "HTTP"
    port     = 80
    url_path = "/"
  }
}

resource "oci_load_balancer_backend" "http_vm1_backend" {
  load_balancer_id = oci_load_balancer_load_balancer.public_lb.id
  backendset_name  = oci_load_balancer_backend_set.http_bs.name
  ip_address       = var.backend_ip_vm1
  port             = 80
  weight           = 1
}

resource "oci_load_balancer_backend" "http_vm2_backend" {
  load_balancer_id = oci_load_balancer_load_balancer.public_lb.id
  backendset_name  = oci_load_balancer_backend_set.http_bs.name
  ip_address       = var.backend_ip_vm2
  port             = 80
  weight           = 1
}

resource "oci_load_balancer_listener" "http_listener" {
  load_balancer_id         = oci_load_balancer_load_balancer.public_lb.id
  name                     = "http-listener"
  port                     = 80
  protocol                 = "HTTP"
  default_backend_set_name = oci_load_balancer_backend_set.http_bs.name
}
