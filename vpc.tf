resource "aws_vpc" "techno-vpc" {
    cidr_block = "25.1.0.0/16"
    assign_generated_ipv6_cidr_block = true
    enable_dns_support = true
    enable_dns_hostnames = true
    tags = {
        Name = "techno-akbar"
    }
}

resource "aws_subnet" "Public-A" {
    vpc_id = aws_vpc.techno-vpc.id
    cidr_block = "25.1.0.0/24"
    ipv6_cidr_block = cidrsubnet(aws_vpc.techno-vpc.ipv6_cidr_block, 8, 0)
    availability_zone = "us-east-1a"
    assign_ipv6_address_on_creation = true
    map_public_ip_on_launch = true
    enable_resource_name_dns_a_record_on_launch = true
    enable_resource_name_dns_aaaa_record_on_launch = true
}

resource "aws_subnet" "Public-B" {
    vpc_id = aws_vpc.techno-vpc.id
    cidr_block = "25.1.2.0/24"
    ipv6_cidr_block = cidrsubnet(aws_vpc.techno-vpc.ipv6_cidr_block, 8, 1)
    assign_ipv6_address_on_creation = true
    availability_zone = "us-east-1b"
    map_public_ip_on_launch = true
    enable_resource_name_dns_a_record_on_launch = true
    enable_resource_name_dns_aaaa_record_on_launch = true
}

resource "aws_subnet" "Private-A" {
    vpc_id = aws_vpc.techno-vpc.id
    cidr_block = "25.1.1.0/24"
    availability_zone = "us-east-1a"
}

resource "aws_subnet" "Private-B" {
    vpc_id = aws_vpc.techno-vpc.id
    cidr_block = "25.1.3.0/24"
    availability_zone = "us-east-1b"
}

resource "aws_internet_gateway" "techno-igw"{
    vpc_id = aws_vpc.techno-vpc.id
}

resource "aws_route_table" "techno-Rt-public" {
    vpc_id = aws_vpc.techno-vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.techno-igw.id
    }

    route {
        ipv6_cidr_block = "::/0"
        gateway_id = aws_internet_gateway.techno-igw.id
    }
}

resource "aws_route_table_association" "techno-public-a" {
    subnet_id = aws_subnet.Public-A.id
    route_table_id = aws_route_table.techno-Rt-public.id
}

resource "aws_route_table_association" "techno-public-b" {
    subnet_id = aws_subnet.Public-B.id
    route_table_id = aws_route_table.techno-Rt-public.id
}

resource "aws_eip" "techno-ip" {
    domain = "vpc"
}

resource "aws_nat_gateway" "techno-ngw" {
    allocation_id = aws_eip.techno-ip.id
    subnet_id = aws_subnet.Public-A.id
}


resource "aws_route_table" "techno-Rt-private" {
    vpc_id = aws_vpc.techno-vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.techno-ngw.id
    }
}

resource "aws_route_table_association" "techno-private-A" {
    subnet_id = aws_subnet.Private-A.id
    route_table_id = aws_route_table.techno-Rt-private.id
}

resource "aws_route_table_association" "techno-private-B" {
    subnet_id = aws_subnet.Private-B.id
    route_table_id = aws_route_table.techno-Rt-private.id
}


resource "aws_security_group" "techno-sg-01" {
    vpc_id = aws_vpc.techno-vpc.id
    name = "techno-sg-lb"
    description = "This sg for lb"

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

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

resource "aws_security_group" "techno-sg-02" {
    vpc_id = aws_vpc.techno-vpc.id
    name = "techno-sg-apps"
    description = "This sg for apps"

    ingress {
        from_port = 2000
        to_port = 2000
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

