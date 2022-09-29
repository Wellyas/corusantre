resource "aws_lb" "ecs_lb" {
  name               = "ecs_lb"
  internal           = true
  load_balancer_type = "network"
  subnets            = aws_subnet.sc_ecs_lb.*.id

}

resource "aws_subnet" "sc_ecs_lb" {
  count = 2
  private_dns_hostname_type_on_launch = "resource-name"
  availability_zone = data.aws_availability_zones.zone.names[count.index]
  vpc_id     = aws_vpc.sidera_cloud.id
  cidr_block        = cidrsubnet(aws_vpc.sidera_cloud.cidr_block, 12, count.index+14)

  tags = {
    Name  = "Zone Ecs loadbalancer"
  }
}