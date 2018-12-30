#
# Variables
#

variable "vpc_name" {
    default = "vpc-demo"
    type = "string"
}

variable "subnet_count" {
    default = 1
    type = "string"
}

variable "ec2_keypair" {
    default = "demo-key"
    type    = "string"
}
