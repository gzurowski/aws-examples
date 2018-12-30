#
# AWS VPC Configuration
#


# VPC
resource "aws_vpc" "demo" {
    cidr_block = "10.0.0.0/16"

    tags = "${
        map(
            "Name", "${var.vpc_name}"
        )
    }"
}

# Public subnets
resource "aws_subnet" "public" {
    count = "${var.subnet_count}"

    availability_zone       = "${data.aws_availability_zones.available.names[count.index]}"
    cidr_block              = "10.0.${count.index}.0/24"
    vpc_id                  = "${aws_vpc.demo.id}"
    map_public_ip_on_launch = true

    tags = "${
        map(
            "Name", "${var.vpc_name} - public - 10.0.${count.index}.0/24 - ${data.aws_availability_zones.available.names[count.index]}"
        )
    }"
}

# Private subnets
resource "aws_subnet" "private" {
    count = "${var.subnet_count}"

    availability_zone       = "${data.aws_availability_zones.available.names[count.index]}"
    cidr_block              = "10.0.${10 + count.index}.0/24"
    vpc_id                  = "${aws_vpc.demo.id}"
    map_public_ip_on_launch = false

        tags = "${
            map(
                "Name", "${var.vpc_name} - private - 10.0.${10 + count.index}.0/24 - ${data.aws_availability_zones.available.names[count.index]}"
            )
        }"
}

# Internet gateway
resource "aws_internet_gateway" "demo" {
    vpc_id = "${aws_vpc.demo.id}"

    tags = "${
        map(
            "Name", "${var.vpc_name}"
        )
    }"
}

# Internet route table
resource "aws_route_table" "public" {
    vpc_id = "${aws_vpc.demo.id}"

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.demo.id}"
    }

    tags = "${
        map(
            "Name", "public - ${var.vpc_name}"
        )
    }"

}

# Associate public subnets with the internet route table
resource "aws_route_table_association" "public" {
    count = "${var.subnet_count}"

    subnet_id           = "${aws_subnet.public.*.id[count.index]}"
    route_table_id      = "${aws_route_table.public.id}"
}
