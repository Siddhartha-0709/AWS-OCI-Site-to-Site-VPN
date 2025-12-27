module "network" {
  source = "./modules/vpc"
}

module "compute" {
  source = "./modules/ec2"

  subnet_id         = module.network.private_subnet_id
  security_group_id = [module.network.security_group_id]
}


output "aws_tunnel_1_outside_ip" {
  value = module.network.aws_tunnel_1_outside_ip
}

output "aws_tunnel_2_outside_ip" {
  value = module.network.aws_tunnel_2_outside_ip
}

output "aws_ec2_instance_private_ip" {
  value = module.compute.instance_private_ip
}