#--------compute/outputs.tf--------
output "private_ip" {
    value = "${data.external.private_ip.result}"
}