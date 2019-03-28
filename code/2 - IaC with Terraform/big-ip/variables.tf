#-------- big-ip/variables.tf --------
variable "as3_rpm_url" {}
variable "do_rpm_url" {}
variable "f5_count" {}
variable "f5_user" {}
variable "f5_profile" {}
variable "f5_instance_type" {}
variable "key_name" {}
variable "public_key_path" {}
variable "subnets" {
  type = "list"
}
variable "security_group" {}
variable "workload_ips" {
  type = "map"
}
