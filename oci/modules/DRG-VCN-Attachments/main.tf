resource "oci_core_drg_attachment" "oci_drg_attachment" {
    drg_id = var.drg_id
    vcn_id = var.vcn_id
    display_name = "OCI VCN - DRG Attachment"
}