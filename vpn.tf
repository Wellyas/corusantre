resource "aws_vpn_gateway" "sideracloud_vpngw" {
  vpc_id = aws_vpc.sidera_cloud.id

  tags = {
    Name = "SideraCloudVPN"
    Owner = "Taleb E."
  }
}

resource "aws_customer_gateway" "sidera_fo" {
  bgp_asn    = 65000
  ip_address = "192.93.158.174"
  type       = "ipsec.1"
  tags = {
    Name = "GW-CCO-FRONT-OFFICE"
    Owner = "Taleb E."
  }
}
resource "aws_customer_gateway" "sidera_bo" {
  bgp_asn    = 65001
  ip_address = "192.93.158.179"
  type       = "ipsec.1"
  tags = {
    Name = "GW-CCO-BACK-OFFICE"
    Owner = "Taleb E."
  }
}
resource "aws_customer_gateway" "sidera_oam" {
  bgp_asn    = 65002
  ip_address = "192.93.158.180"
  type       = "ipsec.1"
  tags = {
    Name = "GW-CCO-OAM"
    Owner = "Taleb E."
  }
}

resource "aws_vpn_connection" "vpnoam" {
  vpn_gateway_id      = aws_vpn_gateway.sideracloud_vpngw.id
  customer_gateway_id = aws_customer_gateway.sidera_oam.id
  type                = "ipsec.1"
  static_routes_only  = true

  tunnel1_ike_versions = ["ikev2"]
  #tunnel1_preshared_key = "Azerty123456789"
  tunnel1_preshared_key = random_password.pskOAM.result

  tunnel1_phase1_dh_group_numbers = [20]
  tunnel1_phase1_encryption_algorithms= ["AES256-GCM-16"]
  tunnel1_phase1_integrity_algorithms= ["SHA2-256"]
  tunnel1_phase1_lifetime_seconds= 28800
  tunnel1_inside_cidr = "169.254.67.56/30"

  tunnel1_phase2_dh_group_numbers= [20]
  tunnel1_phase2_encryption_algorithms= ["AES256-GCM-16"]
  tunnel1_phase2_integrity_algorithms= ["SHA2-256"]
  tunnel1_phase2_lifetime_seconds= 3600

  tunnel1_startup_action= "start"
  
  #local_ipv4_network_cidr = "10.135.190.0/23"
  #remote_ipv4_network_cidr = aws_vpc.sidera_cloud.cidr_block

  #local_ipv4_network_cidr = "169.254.67.58/32"
  #remote_ipv4_network_cidr = "169.254.67.57/32"

  local_ipv4_network_cidr = "169.254.67.56/29"
  remote_ipv4_network_cidr = "169.254.67.56/29"

  tunnel2_ike_versions = ["ikev2"]
  tunnel2_phase1_dh_group_numbers = [20]
  tunnel2_phase1_encryption_algorithms= ["AES256-GCM-16"]
  tunnel2_phase1_integrity_algorithms= ["SHA2-256"]
  tunnel2_phase1_lifetime_seconds= 28800
  tunnel2_inside_cidr = "169.254.67.60/30"
  tunnel2_phase2_dh_group_numbers= [20]
  tunnel2_phase2_encryption_algorithms= ["AES256-GCM-16"]
  tunnel2_phase2_integrity_algorithms= ["SHA2-256"]
  tunnel2_phase2_lifetime_seconds= 3600

  tags = {
    Name = "VPNSideraOnPremiseOAM"
    Owner = "Taleb E."
  }


}

resource "random_password" "pskOAM" {
  length           = 26
  special          = true
  override_special = "_,"
}

resource "aws_vpn_gateway_route_propagation" "sideraOAM" {
  vpn_gateway_id = aws_vpn_gateway.sideracloud_vpngw.id
  route_table_id = aws_vpc.sidera_cloud.default_route_table_id
}

resource "aws_vpn_connection_route" "admin" {
  destination_cidr_block = "10.135.190.0/23"
  vpn_connection_id      = aws_vpn_connection.vpnoam.id
}

output "vpnOAMInfo" {
  value = aws_vpn_connection.vpnoam
  sensitive = true
}