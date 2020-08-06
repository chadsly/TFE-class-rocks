provider "aws" {
  alias      = "gov-west"
  region     = "us-gov-west-1"
  access_key = var.AWS_ACCESS_KEY
  secret_key = var.AWS_SECRET_KEY
}

module "high_altitude" {
  source  = "terraform.cie.vi2e.io/High-Altitude/high-altitude/aws"
  version = "~>1.0.12"
  providers = {
    aws = aws.gov-west
  }

  app_tpl_filepath_filename = "templates/app.tpl"
  application_name          = "gitlab-for-class"
  aws_ami                   = "ami-e7063586"
  ec2_size                  = "t2.medium"
  http_proxy                = "http://internal-transit-c-rELBProx-1FIWKJ1YWJ83C-1424253041.us-gov-west-1.elb.amazonaws.com:3128/"
  no_proxy                  = "'localhost,http://127.0.0.1,10.0.0.0/8'"
  private_subnets           = ["subnet-9d3d7deb", "subnet-2c3b7b48", "subnet-5468cc0d"]
  public_subnets            = ["subnet-3b37774d", "subnet-2f3e7e4b", "subnet-e27dd9bb"]
  ssh_cidrs                 = ["10.0.0.0/8"]
  vpc_id                    = "vpc-8ad750ee"
}