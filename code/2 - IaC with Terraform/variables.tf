variable "f5_count" {}
variable "aws_region" {}
variable "vpc_cidr" {}
variable "public_cidrs" {
  type = "list"
}
variable "key_name" {}
variable "public_key_path" {}
variable "private_key_path" {}
variable "f5_instance_type" {}
variable "f5_user" {}
variable "f5_password" {}
variable "do_rpm_url" {}
variable "as3_rpm_url" {}