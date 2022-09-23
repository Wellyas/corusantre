module "kasmweb" {
  source = "./kasmweb"
  vpc_id              = aws_vpc.sidera_cloud.id
  internet_gateway_id = aws_internet_gateway.gw.id
  key_name            = aws_key_pair.ssh.key_name
  ssh_access_cidr = "10.135.190.0/23"
  https_access_cidr = [ "176.161.232.174/32", "92.184.112.0/24", "176.149.95.90/32", "192.54.145.0/24","192.54.200.0/24"]
  vpn_fw_oam = aws_vpn_gateway.sideracloud_vpngw.id
  private_zone_id = aws_route53_zone.private.id

  depends_on = [
    aws_vpc.sidera_cloud,
    aws_internet_gateway.gw,
    aws_key_pair.ssh,
    aws_vpn_gateway.sideracloud_vpngw,
    aws_route53_zone.private
  ]
}

output "ksm_install" {
  value = module.kasmweb.dbinfo
}

data "aws_availability_zones" "zone" {
  state = "available"
}

output "zones" {
  value = data.aws_availability_zones.zone
  
}