resource "oci_core_drg" "oci_drg" {
	compartment_id = var.compartment_id
	display_name = "OCI Dynamic Routing Gateway"
}

data "oci_core_drg_route_tables" "default_drg_rt" {
  drg_id = oci_core_drg.oci_drg.id
}

output drg_id {
  value       = oci_core_drg.oci_drg.id
  sensitive   = true
  description = "The OCID of the Dynamic Routing Gateway"
  depends_on  = []
}

output "drg_route_table_id" {
  value = data.oci_core_drg_route_tables.default_drg_rt.drg_route_tables[0].id
}
