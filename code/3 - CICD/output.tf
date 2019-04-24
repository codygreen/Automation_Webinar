#-------- output.tf --------
output "private_ip" {
  value = "${join(", ", aws_cloudformation_stack.bigip.*.outputs.Bigip1ExternalInterfacePrivateIp)}"
}
