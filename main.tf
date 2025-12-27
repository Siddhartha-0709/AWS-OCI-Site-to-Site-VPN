module "aws" {
  source = "./aws"
}

output "aws_tunnel_1_outside_ip" {
  value = module.aws.aws_tunnel_1_outside_ip
}

output "aws_tunnel_2_outside_ip" {
  value = module.aws.aws_tunnel_2_outside_ip
}

output "aws_ec2_instance_private_ip" {
  value = module.aws.aws_ec2_instance_private_ip
}


module "oci" {
  source = "./oci"
    aws_tunnel_1_outside_ip = module.aws.aws_tunnel_1_outside_ip
}