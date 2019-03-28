#--------compute/variables.tf--------
variable "cpu" {
    default = 512
}
variable "memory" {
    default = "1024"
}
variable "image" {
    default = "f5devcentral/f5-demo-httpd"
}

variable "security_group" {}
variable "subnet" {
    type = "list"
}
variable "vpc" {}
