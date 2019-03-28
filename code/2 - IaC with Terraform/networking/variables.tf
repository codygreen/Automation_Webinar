#-------- networking/variables.tf --------
variable "vpc_cidr" {}
variable "f5_count" {}
variable "public_cidrs" {
    type = "list"
}
