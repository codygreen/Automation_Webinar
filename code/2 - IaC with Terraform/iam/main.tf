#-------- iam/main.tf --------

# create required IAM policy and role
data "aws_iam_policy_document" "assume_role_doc" {
    statement {
        actions = [
            "sts:AssumeRole"
        ]

        principals = {
            type = "Service"
            identifiers = ["ec2.amazonaws.com"]
        }

        effect = "Allow"

        sid = ""
    }
}

data "aws_iam_policy_document" "f5_ha_policy_doc" {
    statement {
        effect = "Allow"

        actions = [
            "ec2:describeinstancestatus",
            "ec2:describenetworkinterfaces",
            "ec2:assignprivateipaddresses"
        ]

        resources =  [
            "*"
        ]
    }
}

resource "aws_iam_policy" "f5_ha_policy" {
    name = "f5_ha_policy"
    path = "/"
    policy = "${data.aws_iam_policy_document.f5_ha_policy_doc.json}"
}

resource "aws_iam_role" "f5_ha" {
    name = "f5_ha"
    assume_role_policy = "${data.aws_iam_policy_document.assume_role_doc.json}"
}

resource "aws_iam_role_policy_attachment" "f5_ha_attach" {
    role = "${aws_iam_role.f5_ha.name}"
    policy_arn = "${aws_iam_policy.f5_ha_policy.arn}"
}

resource "aws_iam_instance_profile" "f5_profile" {
    name = "f5_profile"
    role = "${aws_iam_role.f5_ha.name}"
}