resource "aws_key_pair" "example_key" {
  key_name   = "DB_Server_Key"
  public_key = file("/home/ubuntu/aws-oci-terraform-project/aws/keyFile/keyfile.pub")
}


resource "aws_instance" "example_server" {
  ami           = "ami-02b8269d5e85954ef"
  instance_type = "t3.micro"
  subnet_id     = var.subnet_id
  key_name      = aws_key_pair.example_key.key_name

  vpc_security_group_ids = var.security_group_id

  tags = {
    Name = "Private VM Database"
  }
}


output "instance_private_ip" {
  value = aws_instance.example_server.private_ip
}