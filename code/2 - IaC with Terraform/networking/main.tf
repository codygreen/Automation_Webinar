#-------- networking/main.tf --------

# Get availability zones
data "aws_availability_zones" "available" {}

# Get My Public IP
data "http" "myIP" {
    url = "http://ipv4.icanhazip.com"
}

# Create VPC
resource "aws_vpc" "f5_demo_vpc" {
    cidr_block = "${var.vpc_cidr}"
    enable_dns_hostnames = true
    enable_dns_support = true

    tags {
        Name = "f5_demo_vpc"
    }
}

# Create Internet Gateway
resource "aws_internet_gateway" "f5_internet_gateway" {
    vpc_id = "${aws_vpc.f5_demo_vpc.id}"

    tags {
        Name = "f5_demo_igw"
    }
}

# Create Public Route Table
resource "aws_route_table" "f5_demo_public_rt" {
    vpc_id = "${aws_vpc.f5_demo_vpc.id}"

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.f5_internet_gateway.id}"
    }

    tags {
        Name = "f5_demo_public_rt"
    }
}

# Create Default Route Table
resource "aws_default_route_table" "f5_demo_private_rt" {
    default_route_table_id = "${aws_vpc.f5_demo_vpc.default_route_table_id}"

    tags {
        Name = "f5_demo_private_rt"
    }
}

# Create Public Subnet
resource "aws_subnet" "f5_public_subnet" {
    count = "${var.f5_count}"
    vpc_id = "${aws_vpc.f5_demo_vpc.id}"
    cidr_block = "${var.public_cidrs[count.index]}"
    map_public_ip_on_launch = true
    availability_zone = "${data.aws_availability_zones.available.names[count.index]}"

    tags {
        Name = "f5_demo_public_subnet_${count.index + 1}"
    }
}

# Associate Subnet to Route Table
resource "aws_route_table_association" "f5_demo_public_assoc" {
    count           = "${aws_subnet.f5_public_subnet.count}"
    subnet_id       = "${aws_subnet.f5_public_subnet.*.id[count.index]}"
    route_table_id  = "${aws_route_table.f5_demo_public_rt.id}"
}

# Create Security Group
resource "aws_security_group" "f5_demo_sg" {
  name = "f5_demo_sg"
  description = "F5 BIG-IP Terraform Demo Security Group"
  vpc_id = "${aws_vpc.f5_demo_vpc.id}"

    # MGMT UI
    ingress {
        from_port = 8443
        to_port = 8443
        protocol = "tcp"
        cidr_blocks = ["${chomp(data.http.myIP.body)}/32"]
    }

    # SSH
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["${chomp(data.http.myIP.body)}/32"]
    }

    # HTTP
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # HTTPS
    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}
