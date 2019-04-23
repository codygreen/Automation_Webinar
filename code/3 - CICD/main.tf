#-------- main.tf --------

terraform {
  backend "s3" {
    bucket = "cody-terraform"
    key    = "cicd_webinar/terraform.tfstate"
    region = "us-east-2"
  }
}

# Get My Public IP
data "http" "myIP" {
  url = "http://api.ipify.org/"
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

# Deploy Demo App
module "compute" {
  source = "github.com/codygreen/Terraform//modules/aws/compute-ec2"

  name           = "${var.name}"
  vpc_id         = "${data.aws_vpc.cicd.id}"
  vpc_cidr       = "${var.vpc_cidr}"
  ssh_key        = "${var.ssh_key}"
  subnet_id      = "${data.aws_subnet_ids.cicd.ids[0]}"
  instance_count = 1
}

# Deploy BIG-IP
module "big-ip" {
  source = "github.com/codygreen/Terraform//modules/aws/big-ip/single-nic"

  name               = "${var.name}"
  vpc_id             = "${data.aws_vpc.cicd.id}"
  vpc_cidr           = "${var.vpc_cidr}"
  key_name           = "${var.ssh_key}"
  subnet_id          = "${data.aws_subnet_ids.cicd.ids[0]}"
  instance_count     = 1
  allowed_mgmt_cidrs = ["${chomp(data.http.myIP.body)}/32"]
}

# Configure BIG-IP
provider "bigip" {
  address  = "${module.big-ip.public_ip}"
  username = "admin"
  password = "${module.big-ip.public_ip}"
}

// Label is used to identify which Json payload to use.
resource "bigip_app_as3" "as3-example1" {
  label    = "Sample 1"
  ident    = "sanjoseid"
  jsonfile = "${file("as3_nginx.json")}"
}
