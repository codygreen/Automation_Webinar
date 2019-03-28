#-------- networking/outputs.tf --------
output "public_subnets" {
  value = "${aws_subnet.f5_public_subnet.*.id}"
}
output "security_group" {
  value = "${aws_security_group.f5_demo_sg.id}"
}
output "vpc" {
  value = "${aws_vpc.f5_demo_vpc.id}"
}
