#-------- output.tf --------
output "public_ip" {
  value = "${join(", ", aws_cloudformation_stack.bigip.*.outputs.Bigip1ExternalInterfacePrivateIp)}"
}
