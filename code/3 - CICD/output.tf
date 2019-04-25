#-------- output.tf --------
output "private_ip" {
  value = "${aws_cloudformation_stack.bigip.outputs["Bigip1ExternalInterfacePrivateIp"]}"

  depends_on = [
    # needed for CFT output
    "aws_cloudformation_stack.bigip",
  ]
}

output "password" {
  value = "${random_string.password.result}"
}
