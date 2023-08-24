provider "aws" {
  region = "${var.region}"
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
}

resource "aws_instance" "eip_instance_example" {
  ami           = "${var.ami}"
  instance_type = "${var.instance_type}"
}  
  
  
resource "aws_eip" "myeip" {
  vpc      = true
}
resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.eip_instance_example.id
  allocation_id = aws_eip.myeip.id
}
