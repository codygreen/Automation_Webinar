#-------- main.tf --------

terraform {
  backend "s3" {
    bucket = "cody-terraform"
    key    = "cicd_webinar/terraform.tfstate"
    region = "us-east-2"
  }
}

# Get VPC ID
provider "aws" {
  region = "${var.aws_region}"
}

data aws_vpc "cicd" {
  cidr_block = "${var.vpc_cidr}"

  tags = {
    Name = "${var.name}"
  }
}

# Get Subnet ID
data "aws_subnet_ids" "cicd" {
  vpc_id = "${data.aws_vpc.cicd.id}"
}

module "compute" {
  source = "github.com/codygreen/Terraform//modules/aws/compute-ec2"

  name           = "${var.name}"
  vpc_id         = "${data.aws_vpc.cicd.id}"
  vpc_cidr       = "${var.vpc_cidr}"
  ssh_key        = "${var.ssh_key}"
  subnet_id      = "${data.aws_subnet_ids.cicd.ids[0]}"
  instance_count = 1
}