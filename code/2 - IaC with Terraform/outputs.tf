#--------root/outputs.tf--------
output "ECS Private IPs" {
  value = "${module.compute.private_ip}"
}

output "BIG-IP IPs" {
  value = "${module.big-ip.public_ip}"
}

output "BIG-IP Password" {
    value = "${module.big-ip.password}"
}