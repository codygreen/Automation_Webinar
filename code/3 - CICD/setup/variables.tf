#-------- setup/variables.tf --------
variable "aws_region" {
  default = "us-east-2"
}

variable "name" {
  default = "cicd_demo"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public_cidrs" {
  default = [
    "10.0.1.0/24",
    "10.0.2.0/24",
  ]
}

variable "ssh_key" {
  default = "cody-key"
}
