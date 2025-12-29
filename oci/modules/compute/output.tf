output "app_instance_private_ip_1" {
  value       = oci_core_instance.app_instance1.private_ip
  sensitive   = true
  description = "Private IP address of the app instance"
  depends_on  = []
}
output "app_instance_private_ip_2" {
  value       = oci_core_instance.app_instance2.private_ip
  sensitive   = true
  description = "Private IP address of the app instance"
  depends_on  = []
}