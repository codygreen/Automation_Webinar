#-------- big-iputputs.tf --------
output "public_ip" {
  value = "${join(", ", aws_instance.f5_bigip.*.public_ip)}"
}

output "password" {
    value = "${random_string.password.result}"
}