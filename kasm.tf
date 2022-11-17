module "kasmweb" {
  source              = "./kasmweb"
  vpc_id              = aws_vpc.sidera_cloud.id
  internet_gateway_id = aws_internet_gateway.gw.id
  key_name            = aws_key_pair.ssh.key_name
  #ssh_access_cidr     = aws_subnet.sc_access.cidr_block
  ssh_access_cidr     = "10.135.0.0/16"
  https_access_cidr   = ["176.161.232.174/32", "92.184.112.0/24", "176.149.95.90/32", "192.54.145.0/24", "192.54.200.0/24", "10.135.191.0/24","192.93.158.168/32","197.230.148.2/32","86.242.126.194/32"]
  vpn_fw_oam          = aws_vpn_gateway.sideracloud_vpngw.id
  private_zone_id     = aws_route53_zone.private.id
  proxies_servers_cidr = ["10.135.191.4/32"]

  depends_on = [
    aws_vpc.sidera_cloud,
    aws_internet_gateway.gw,
    aws_key_pair.ssh,
    aws_vpn_gateway.sideracloud_vpngw,
    aws_route53_zone.private
  ]
}

output "dbinfo" {
  value = module.kasmweb.dbinfo
}

output "dbsh" {
  value     = module.kasmweb.installdb
  sensitive = true
}

output "appsh" {
  value     = module.kasmweb.appinstall
  sensitive = true
}

output "arn_validation" {
  value = module.kasmweb.arn_validation
}

output "debug" {
  value = module.kasmweb.debug
}