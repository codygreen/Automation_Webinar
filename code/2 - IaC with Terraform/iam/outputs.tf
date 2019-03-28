#-------- iam/output.tf --------
output "f5_profile" {
  value = "${aws_iam_instance_profile.f5_profile.id}"
}