#-------- setup/main.tf --------
provider "aws" {
  region = "${var.aws_region}"
}

# Get availability zones
data "aws_availability_zones" "available" {}

# Get My Public IP
data "http" "myIP" {
  url = "http://api.ipify.org/"
}

# create IAM user
resource "aws_iam_user" "automation_lab" {
  name          = "${var.name}-jenkins"
  path          = "/lab/"
  force_destroy = true
}

# add users to group
resource "aws_iam_group_membership" "automation_lab" {
  name  = "automation_lab_group_membership"
  group = "${aws_iam_group.automation_lab.name}"
  users = ["${aws_iam_user.automation_lab.*.name}"]
}

# create IAM group
resource "aws_iam_group" "automation_lab" {
  name = "${var.name}-jenkins"
}

# data "aws_iam_policy" "AWSCloud9User" {
#   arn = "arn:aws:iam::aws:policy/Administrator"
# }

data "aws_iam_policy" "admin" {
  arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# attach policy to IAM group
resource "aws_iam_group_policy_attachment" "automation_lab_attach" {
  group      = "${aws_iam_group.automation_lab.name}"
  policy_arn = "${data.aws_iam_policy.admin.arn}"
}

# create access key
resource "aws_iam_access_key" "cicd" {
  count = "${aws_iam_user.automation_lab.count}"
  user  = "${aws_iam_user.automation_lab.*.name[count.index]}"
}

# create required VPC
resource "aws_vpc" "vpc" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags {
    Name = "${var.name}"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "ig" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags {
    Name = "${var.name}_igw"
  }
}

# Create Public Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = "${aws_vpc.vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.ig.id}"
  }

  tags {
    Name = "${var.name}_public_rt"
  }

  depends_on = ["aws_internet_gateway.ig"]
}

# Create Default Route Table
resource "aws_default_route_table" "private_rt" {
  default_route_table_id = "${aws_vpc.vpc.default_route_table_id}"

  tags {
    Name = "${var.name}_private_rt"
  }
}

# Create Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = "${aws_vpc.vpc.id}"
  cidr_block              = "${var.public_cidrs[0]}"
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_availability_zones.available.names[0]}"

  tags {
    Name = "${var.name}_public_subnet"
  }
}

# Associate Subnet to Route Table
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = "${aws_subnet.public_subnet.id}"
  route_table_id = "${aws_route_table.public_rt.id}"

  depends_on = ["aws_subnet.public_subnet"]
}

# Create Security Group
resource "aws_security_group" "cicd_sg" {
  vpc_id      = "${aws_vpc.vpc.id}"
  description = "F5 BIG-IP Terraform Demo Security Group"

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myIP.body)}/32"]
  }

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myIP.body)}/32"]
  }

  # HTTP
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myIP.body)}/32", "${var.GitHubIPs}"]
  }

  # HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myIP.body)}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Find Ubuntu AMI
data "aws_ami" "compute" {
  most_recent = true
  owners      = ["amazon"] # Canonical

  filter {
    name   = "name"
    values = ["amzn-ami-hvm*"] # Ubuntu Bionic 
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_iam_instance_profile" "cicd" {
  name = "lab_profile"
  role = "${aws_iam_role.role.name}"
}

resource "aws_iam_role" "role" {
  name = "lab_role"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_instance" "cicd" {
  ami = "${data.aws_ami.compute.id}"

  #   associate_public_ip_address = true

  iam_instance_profile   = "${aws_iam_instance_profile.cicd.id}"
  instance_type          = "t2.micro"
  key_name               = "${var.ssh_key}"
  vpc_security_group_ids = ["${aws_security_group.cicd_sg.id}"]
  subnet_id              = "${aws_subnet.public_subnet.id}"
  tags = {
    Terraform = true
    Name      = "CICD"
  }
}

resource "null_resource" "aws_credentials" {
  provisioner "remote-exec" {
    connection {
      host        = "${aws_instance.cicd.public_ip}"
      type        = "ssh"
      user        = "ec2-user"
      private_key = "${file("~/.ssh/${var.ssh_key}.pem")}"
    }

    inline = [<<EOF
      sudo runuser -l jenkins -c 'mkdir ~/.aws'
      sudo runuser -l jenkins -c "echo -e '[default]\nregion=${var.aws_region}\naws_access_key_id=${aws_iam_access_key.cicd.id}\naws_secret_access_key=${aws_iam_access_key.cicd.secret}' > ~/.aws/credentials"
      EOF
    ]
  }
}

# run ansible playbook
resource "null_resource" "jenkins" {
  depends_on = ["aws_instance.cicd"]

  provisioner "remote-exec" {
    connection {
      host        = "${aws_instance.cicd.public_ip}"
      type        = "ssh"
      user        = "ec2-user"
      private_key = "${file("~/.ssh/${var.ssh_key}.pem")}"
    }

    inline = [
      "sudo yum update -y",
      "sudo yum install java-1.8.0-openjdk.x86_64 -y",
      "sudo yum remove java-1.7.0-openjdk -y",
      "sudo wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins.io/redhat/jenkins.repo",
      "sudo rpm --import https://pkg.jenkins.io/redhat/jenkins.io.key",
      "sudo yum install jenkins -y",
      "curl https://raw.githubusercontent.com/codygreen/Automation_Webinar/master/code/3%20-%20CICD/setup/basic-security.groovy -o basic-security.groovy",
      "sudo mkdir /var/lib/jenkins/init.groovy.d",
      "sudo cp basic-security.groovy /var/lib/jenkins/init.groovy.d/",
      "sudo chown -R jenkins:jenkins /var/lib/jenkins/init.groovy.d",
      "wget http://127.0.0.1:8080/jnlpJars/jenkins-cli.jar",
      "export JENKINS_URL=http://localhost:8080",
      "java -jar jenkins-cli.jar -auth admin:someAdminPass install-plugin github -restart",
      "java -jar jenkins-cli.jar -auth admin:someAdminPass install-plugin workflow-aggregator -restart",
      "java -jar jenkins-cli.jar -auth admin:someAdminPass install-plugin job-dsl -restart",
      "sudo service jenkins start",
      "sudo yum install -y git",
      "sudo pip install ansible",
      "sudo pip install f5-sdk",
      "wget https://releases.hashicorp.com/terraform/0.11.13/terraform_0.11.13_linux_amd64.zip",
      "unzip terraform*",
      "sudo mv terraform /usr/local/bin/",
      "sudo chsh -s /bin/bash jenkins",
      "sudo /usr/local/bin/ansible-galaxy install --roles-path /etc/ansible/roles nginxinc.nginx",
      "sudo sh -c 'echo \"JAVA_ARGS=-Djava.awt.headless=true -Djenkins.install.runSetupWizard=false\" >> /etc/sysconfig/jenkins'",
    ]
  }
}
