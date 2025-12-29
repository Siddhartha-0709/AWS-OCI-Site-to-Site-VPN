# AWS-OCI Multi-Cloud IPSec VPN Connection - Deployment Steps

## Overview
This project demonstrates a secure multi-cloud architecture connecting Oracle Cloud Infrastructure (OCI) and Amazon Web Services (AWS) using an IPSec VPN tunnel. The architecture implements a distributed application where the application tier runs on OCI and the database tier runs on AWS, connected through a private, encrypted IPSec tunnel.

**Total Deployment Time:** ~30-40 minutes  
**Shared Secret:** `qwertyuiopasdfghjkl`  
**IKE Version:** IKEv2  
**Routing Type:** Static


## Architecture Diagram

![alt text](https://res.cloudinary.com/djf6ew5uc/image/upload/v1767019629/OCI-AWS_MultiCloud.drawio_xe4okc.png)

---
## Step 1: Deploy OCI Infrastructure (Without IPSec)

### Command:
```bash
cd oci
terraform init
terraform apply -var="create_ipsec=false"
```

### Expected Output:

```
Apply complete! Resources: 21 added, 0 changed, 0 destroyed.

Outputs:
cpe_id = "Not created yet"
drg_id = "ocid1.drg.oc1.ap-mumbai-1.aaaaaaaajlnd66h3zen2mfgpz53fcvrbp7tugmrqursivca5ycgnhg7p55va"
ipsec_connection_id = "Not created yet"
oci_vpn_tunnel_public_ip = "Not created yet - run with create_ipsec=true"
oci_vpn_tunnel_status = "Not created yet"
private_subnet_id = "ocid1.subnet.oc1.ap-mumbai-1.aaaaaaaakcg6jm7mlmsrdqfx55a7lxlflgv334tjbscuz5bzvfmkbly3pyzq"
public_subnet_id = "ocid1.subnet.oc1.ap-mumbai-1.aaaaaaaap2px3nl4nhjzotfgajp7vmhkoxj6waor3462x2vedjobi3rzecrq"
vcn_cidr = "10.0.0.0/16"
vcn_id = "ocid1.vcn.oc1.ap-mumbai-1.amaaaaaas4ztmliatd3blf4h6rhbqik5vg4euqus4vpek2plyex7obcgigjq"
```

**Result:** OCI VCN, subnets, DRG, VMs and load balancers created. No IPSec connection yet.

---

## Step 2: Deploy AWS Infrastructure (With Placeholder IP)

### Command:
```bash
cd ../aws
terraform init
terraform apply -var="oci_tunnel_public_ip=1.1.1.1"
```

### Expected Output (Exact Resource ID and IP Addresses may Differ):
```
Apply complete! Resources: 16 added, 0 changed, 0 destroyed.

Outputs:
aws_tunnel_1_inside_cidr = "169.254.57.124/30"
aws_tunnel_1_public_ip = "13.201.197.51"                    ← COPY THIS IP
customer_gateway_id = "cgw-00d4fb2284cae7b8b"
private_subnet_id = "subnet-0b225ddf670da4ecf"
public_subnet_id = "subnet-0f9de85973fa0c157"
security_group_id = "sg-0289af9a578bdc743"
tunnel_1_preshared_key = <sensitive>
vpc_cidr = "192.168.0.0/16"
vpc_id = "vpc-0109fff12635b847d"
vpn_connection_id = "vpn-0e2d505162a11004a"
vpn_gateway_id = "vgw-0993ddbeaaad2311d"
```

**Action Required:** Copy the `aws_tunnel_1_public_ip` value for the next step.

---

## Step 3: Create OCI IPSec Connection (With AWS Tunnel IP)

### Command:
```bash
cd ../oci
terraform apply \
  -var="create_ipsec=true" \
  -var="aws_vpn_gateway_ip=13.201.197.51"
```
*Replace `13.201.197.51` with your actual AWS tunnel IP from Step 2*

### Expected Output (Exact Resource ID and IP Addresses may Differ):
```
Apply complete! Resources: 3 added, 1 changed, 0 destroyed.

Outputs:
cpe_id = "ocid1.cpe.oc1.ap-mumbai-1.aaaaaaaau5br44ox424etn6obwhqtwllxf634x6md2bffqafll25dqxsaidq"
drg_id = "ocid1.drg.oc1.ap-mumbai-1.aaaaaaaajlnd66h3zen2mfgpz53fcvrbp7tugmrqursivca5ycgnhg7p55va"
ipsec_connection_id = "ocid1.ipsecconnection.oc1.ap-mumbai-1.amaaaaaas4ztmliafa3c4tw64d3stvbgzdenrogzdxjpoc64vijlsgqpwkta"
oci_vpn_tunnel_public_ip = "152.67.16.222"                  ← COPY THIS IP
oci_vpn_tunnel_status = "UP"
private_subnet_id = "ocid1.subnet.oc1.ap-mumbai-1.aaaaaaaakcg6jm7mlmsrdqfx55a7lxlflgv334tjbscuz5bzvfmkbly3pyzq"
public_subnet_id = "ocid1.subnet.oc1.ap-mumbai-1.aaaaaaaap2px3nl4nhjzotfgajp7vmhkoxj6waor3462x2vedjobi3rzecrq"
vcn_cidr = "10.0.0.0/16"
vcn_id = "ocid1.vcn.oc1.ap-mumbai-1.amaaaaaas4ztmliatd3blf4h6rhbqik5vg4euqus4vpek2plyex7obcgigjq"
```

**Action Required:** Copy the `oci_vpn_tunnel_public_ip` value for the next step.  
**Note:** OCI tunnel status shows "UP" immediately on OCI side.

---

## Step 4: Update AWS with Real OCI Tunnel IP

### Command:
```bash
cd ../aws
terraform apply -var="oci_tunnel_public_ip=152.67.16.222"
```
*Replace `152.67.16.222` with your actual OCI tunnel IP from Step 3*

### Expected Output (Exact Resource ID and IP Addresses may Differ):
```
Apply complete! Resources: 1 added, 1 changed, 1 destroyed.

Outputs:
aws_tunnel_1_inside_cidr = "169.254.57.124/30"
aws_tunnel_1_public_ip = "13.201.197.51"
customer_gateway_id = "cgw-0b82ce7d3b62897fb"               ← NEW CGW ID
private_subnet_id = "subnet-0b225ddf670da4ecf"
public_subnet_id = "subnet-0f9de85973fa0c157"
security_group_id = "sg-0289af9a578bdc743"
tunnel_1_preshared_key = <sensitive>
vpc_cidr = "192.168.0.0/16"
vpc_id = "vpc-0109fff12635b847d"
vpn_connection_id = "vpn-0e2d505162a11004a"
vpn_gateway_id = "vgw-0993ddbeaaad2311d"
```

**⚠️ IMPORTANT:** This step takes **20-30 minutes** to complete. AWS is:
- Creating new Customer Gateway with real OCI IP
- Recreating VPN connection
- Establishing IPSec tunnel
- Negotiating IKE Phase 1 and Phase 2

---

## Step 5: Verify Tunnel Status

### Check AWS Tunnel Status:

Login to the AWS Console and find the respective IPSec Connection and check the tunnel status.
Note- Online one should be active and that is fine!

## Step 6: Test Connectivity

### SSH into any one of the OCI VMs using the Public Load Balancer's Public IP:
### Test Ping:
```bash
# From Host System
ssh -i <keyFile.key> ubuntu@<loadbalancer-public-ip>

# From OCI Compute instance
ping <aws-vm-private-ip>

# SSH into AWS EC2 instance using keyfile from the OCI VM
ssh -i <keyFile.key> ubuntu@<aws-vm-private-ip>

# From AWS EC2 instance
ping <oci-vm-private-ip>
```

**Expected:** Successful ping responses across the IPSec tunnel! 🎉

---



## Configuration Details

| Parameter | Value |
|-----------|-------|
| **Shared Secret** | `qwertyuiopasdfghjkl` |
| **IKE Version** | IKEv2 |
| **Routing** | Static |
| **DPD Timeout** | 30 seconds |
| **DPD Mode** | RESPOND_ONLY |
| **Phase 1 Lifetime** | 28800 seconds (8 hours) |
| **Phase 2 Lifetime** | 3600 seconds (1 hour) |
| **DH Group** | Group 14 (2048-bit) |

---

## Traffic Flow

```
User (Internet)
    │
    ▼
Load Balancer (OCI Public IP)
    │
    ▼
Application VM (OCI Private Subnet: 10.0.1.x)
    │
    ▼
DRG (OCI Dynamic Routing Gateway)
    │
    ▼
IPSec Tunnel (Encrypted)
    │
    ▼
VGW (AWS Virtual Private Gateway)
    │
    ▼
Database Instance (AWS Private Subnet: 192.168.1.x)
    
    
Response flows back through the same path
```

## Monitoring & Maintenance

### Health Checks
- Monitor IPSec tunnel status on both sides
- Load balancer health checks for application VMs
- Database connection monitoring
- VPN tunnel metrics (latency, packet loss)

### Alerts
- IPSec tunnel down
- Load balancer unhealthy targets
- Database connection failures
- High latency on VPN tunnel

## Troubleshooting

### Tunnel Status Shows "DOWN"
- Wait 20-30 minutes after Step 4
- Check security lists/groups allow UDP 500 and 4500
- Verify shared secrets match on both sides
- Check route tables have correct routes

### Cannot Ping Between Instances
- Verify instances are in private subnets
- Check security groups/lists allow ICMP
- Verify route tables point to DRG/VGW
- Confirm tunnel status is "UP" on both sides

### View Detailed VPN Configuration
```bash
# AWS
aws ec2 describe-vpn-connections --vpn-connection-ids <vpn_connection_id>

# OCI
oci network ip-sec-connection get --ipsc-id <ipsec_connection_id>
```

---

## Notes

- Load balancers created in Step 1 may not be fully functional until web servers (nginx/apache) are installed on VMs
- Step 4 is the longest step - AWS needs time to establish the IPSec tunnel
- Both tunnel endpoints must have matching configurations for successful connection
- Private instances need proper security list/group rules for cross-cloud communication

---

## Success Criteria

✅ OCI tunnel status: "UP"  
✅ AWS tunnel status: "UP"  
✅ Ping works between AWS EC2 and OCI Compute instances  
✅ Private subnet routing works across clouds


**Note:** This is a reference architecture. Please review and adjust security configurations, instance sizes, and networking parameters based on your specific requirements and compliance needs.