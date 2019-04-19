#------- variables.tf --------

variable "aws_region" {
  default = "us-east-2"
}

variable "name" {
  default = "cicd_demo"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "ssh_key" {
  default = "cody-key"
}
