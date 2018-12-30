data "aws_ami" "demo" {
    most_recent         = true

    filter {
        name    = "owner-alias"
        values  = ["amazon"]
    }

    filter {
        name    = "name"
        values  = ["amzn2-ami-hvm-*"]
    }
}

#
# web server (located in public subnet)
#

resource "aws_security_group" "webserver" {
    name    = "${var.vpc_name} - webserver"
    vpc_id  = "${aws_vpc.demo.id}"

    # ssh
    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    # web
    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port   = 8
        to_port     = 0
        protocol    = "icmp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # Note: Must explicitly allow all outbound traffic as Terraform removes this automatically created rule by default (see https://www.terraform.io/docs/providers/aws/r/security_group.html).
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

}

resource "aws_launch_configuration" "webserver" {
    name            = "${var.vpc_name} - webserver"
    //image_id        = "${data.aws_ami.demo.id}"
    image_id = "ami-009d6802948d06e52"
    instance_type   = "t2.nano"
    key_name        = "${var.ec2_keypair}"
    security_groups = ["${aws_security_group.webserver.id}"]
    associate_public_ip_address = true
}

resource "aws_autoscaling_group" "webserver" {
    launch_configuration    = "${aws_launch_configuration.webserver.id}"
    vpc_zone_identifier     = ["${aws_subnet.public.*.id}"]
    min_size                = 1
    max_size                = "${var.subnet_count}"
    
    tags = [{
        key                 = "Name"
        value               = "${var.vpc_name} - webserver"
        propagate_at_launch = true
    }]
}

#
# database server (located in private subnet)
#

resource "aws_security_group" "database-server" {
    name    = "${var.vpc_name} - database-server"
    vpc_id  = "${aws_vpc.demo.id}"

    # ssh
    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        security_groups = ["${aws_security_group.webserver.id}"]
    }
    # web
    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        security_groups = ["${aws_security_group.webserver.id}"]
    }
    # icmp
    ingress {
        from_port       = 8
        to_port         = 0
        protocol        = "icmp"
        security_groups = ["${aws_security_group.webserver.id}"]
    }

    # Note: Must explicitly allow all outbound traffic as Terraform removes this automatically created rule by default (see https://www.terraform.io/docs/providers/aws/r/security_group.html).
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_launch_configuration" "database-server" {
    name            = "${var.vpc_name} - database-server"
    // image_id        = "${data.aws_ami.demo.id}"
    image_id = "ami-009d6802948d06e52"
    instance_type   = "t2.nano"
    key_name        = "${var.ec2_keypair}"
    security_groups = ["${aws_security_group.database-server.id}"]
    associate_public_ip_address = false
}

resource "aws_autoscaling_group" "database-server" {
    launch_configuration    = "${aws_launch_configuration.database-server.id}"
    vpc_zone_identifier     = ["${aws_subnet.private.*.id}"]
    min_size                = 1
    max_size                = "${var.subnet_count}"
    
    tags = [{
        key                 = "Name"
        value               = "${var.vpc_name} - database-server"
        propagate_at_launch = true
    }]
}

/*
resource "aws_instance" "webserver" {
    ami           = "${data.aws_ami.demo.id}"
    instance_type = "t2.nano"
    subnet_id     = "${element(aws_subnet.public.*.id, 0)}"
    key_name      = "${var.ec2_keypair}"
    
    tags = "${
        map(
            "Name", "${var.vpc_name} - webserver"
        )
    }"
}
*/