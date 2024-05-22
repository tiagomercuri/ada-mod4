resource "aws_vpc" "ecs_vpc" {
  cidr_block = var.vpc_cidr_block

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_internet_gateway" "ecs_igw" {
  vpc_id = aws_vpc.ecs_vpc.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

resource "aws_subnet" "ecs_subnet" {
  count                   = length(var.subnet_cidr_blocks)
  vpc_id                  = aws_vpc.ecs_vpc.id
  cidr_block              = var.subnet_cidr_blocks[count.index]
  availability_zone       = element(var.availability_zones, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-subnet-${count.index}"
  }
}

resource "aws_route_table" "ecs_route_table" {
  vpc_id = aws_vpc.ecs_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ecs_igw.id
  }

  tags = {
    Name = "${var.project_name}-route-table"
  }
}

resource "aws_route_table_association" "ecs_subnet_association" {
  count          = length(var.subnet_cidr_blocks)
  subnet_id      = aws_subnet.ecs_subnet[count.index].id
  route_table_id = aws_route_table.ecs_route_table.id
}
