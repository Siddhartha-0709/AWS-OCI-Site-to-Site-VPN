


resource "aws_key_pair" "example_key" {
  key_name   = "AppVM-Key"
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

