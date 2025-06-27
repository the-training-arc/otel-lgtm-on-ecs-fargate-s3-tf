
data "aws_vpc" "selected" { # rnd vpc
  id = "vpc-02c4d6c4d3e3e2545"
}

# Fetch all public subnets in the VPC (those with 'public' in the name)
data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
}

data "aws_subnet" "public_a" {
  vpc_id            = data.aws_vpc.selected.id
  availability_zone = "ap-southeast-1a"
  filter {
    name   = "tag:Name"
    values = ["ap-southeast-1a-public-subnet"]
  }
}
data "aws_subnet" "public_b" {
  vpc_id            = data.aws_vpc.selected.id
  availability_zone = "ap-southeast-1b"
  filter {
    name   = "tag:Name"
    values = ["ap-southeast-1b-public-subnet"]
  }
}
data "aws_subnet" "public_c" {
  vpc_id            = data.aws_vpc.selected.id
  availability_zone = "ap-southeast-1c"
  filter {
    name   = "tag:Name"
    values = ["ap-southeast-1c-public-subnet"]
  }
}

locals {
  public_subnet_ids = [
    data.aws_subnet.public_a.id,
    data.aws_subnet.public_b.id,
    data.aws_subnet.public_c.id
  ]
}
