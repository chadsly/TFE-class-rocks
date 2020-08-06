provider "aws" {
  region     = "us-gov-west-1"
  access_key = var.AWS_ACCESS_KEY
  secret_key = var.AWS_SECRET_KEY
}

resource "aws_instance" "app" {
  ami           = "ami-adecdbcc"
  instance_type = "t2.micro"
  subnet_id     = "subnet-9d3d7deb"

  tags = {
    Name = "chads app"
  }
}