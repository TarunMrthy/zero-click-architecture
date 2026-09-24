provider "aws" {
  region = "ap-south-1"
}

resource "aws_vpc" "first_network" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "MyFirstCloudNetwork"
  }
}
