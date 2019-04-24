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

resource "random_string" "password" {
  length           = 16
  special          = true
  override_special = "@"
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

resource "aws_cloudformation_stack" "bigip" {
  name = "cicd-demo-bigip"

  parameters = {
    Vpc          = "${data.aws_vpc.cicd.id}"
    subnet1Az1   = "${data.aws_subnet_ids.cicd.ids[0]}"
    imageName    = "Good25Mbps"
    instanceType = "m5.large"
    sshKey       = "${var.ssh_key}"

    # restrictedSrcAddress    = ["${chomp(data.http.myIP.body)}/32", "${var.vpc_cidr}"]
    # restrictedSrcAddress = "${join(", ", "${list("${chomp(data.http.myIP.body)}/32", "${var.vpc_cidr}")}")}"
    restrictedSrcAddress = "${var.vpc_cidr}"

    restrictedSrcAddressApp = "0.0.0.0/0"
    declarationUrl          = "https://raw.githubusercontent.com/codygreen/Automation_Webinar/master/code/3%20-%20CICD/as3_nginx.json"
  }

  template_url = "https://s3.amazonaws.com/f5-cft/f5-existing-stack-payg-1nic-bigip.template"
  capabilities = ["CAPABILITY_IAM"]
}

# # Deploy BIG-IP - this doesn't include AS3 Service Discovery or latest cloudlibs 
# module "big-ip" {
#   source = "github.com/codygreen/Terraform//modules/aws/big-ip/single-nic"


#   name               = "${var.name}"
#   vpc_id             = "${data.aws_vpc.cicd.id}"
#   vpc_cidr           = "${var.vpc_cidr}"
#   key_name           = "${var.ssh_key}"
#   subnet_id          = "${data.aws_subnet_ids.cicd.ids[0]}"
#   instance_count     = 1
#   allowed_mgmt_cidrs = ["${chomp(data.http.myIP.body)}/32"]
# }


# Configure BIG-IP - this is based on test methods that are not upstreamed yet
# provider "bigip" {
#   address  = "${module.big-ip.public_ip}"
#   username = "admin"
#   password = "${module.big-ip.password}"
# }


# // Label is used to identify which Json payload to use.
# resource "bigip_app_as3" "as3-example1" {
#   label    = "Sample 1"
#   ident    = "sanjoseid"
#   jsonfile = "${file("as3_nginx.json")}"
# }

