resource "aws_subnet" "sc_eks" {
  count = 2
  private_dns_hostname_type_on_launch = "resource-name"
  availability_zone = data.aws_availability_zones.zone.names[count.index]
  vpc_id     = aws_vpc.sidera_cloud.id
  cidr_block        = cidrsubnet(aws_vpc.sidera_cloud.cidr_block, 12, count.index+20)

  tags = {
    Name  = "Zone EKS"
  }
}

resource "aws_route_table_association" "nat_sc_eks" {
  count = length(aws_subnet.sc_eks)
  subnet_id      = aws_subnet.sc_eks[count.index].id
  route_table_id = aws_route_table.eks.id
}

resource "aws_route_table" "eks" {
  vpc_id = aws_vpc.sidera_cloud.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.gw.id
  }
}
resource "aws_vpn_gateway_route_propagation" "sideraOAM-eks" {
  vpn_gateway_id = aws_vpn_gateway.sideracloud_vpngw.id
  route_table_id = aws_route_table.eks.id
}

locals {
  cluster_name = "sidera-eks-${random_string.suffix.result}"
  cluster_version = "1.24"
  gui_access = ["10.135.190.0/23"]
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.3.1"

  cluster_name    = local.cluster_name
  cluster_version = local.cluster_version
  
  cluster_endpoint_private_access = true 
  
  vpc_id     = aws_vpc.sidera_cloud.id
  subnet_ids = aws_subnet.sc_eks.*.id

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"

    attach_cluster_primary_security_group = true
    use_custom_launch_template = false

    # Disabling and using externally provided security groups
    #create_security_group = false

    key_name = aws_key_pair.ssh.key_name
  }

  eks_managed_node_groups = {
    one = {
      name = "node-group-1"

      instance_types = ["t3.small"]

      min_size     = 1
      max_size     = 3
      desired_size = 2

      pre_bootstrap_user_data = <<-EOT
      echo 'foo bar'
      EOT

      vpc_security_group_ids = [
        aws_security_group.sg_admin_from_wab.id,
        aws_security_group.sg_eks.id
      ]
    }

  }
}

resource "aws_route53_record" "ekscname" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "k8s"
  type    = "CNAME"
  ttl     = 300
  records = [
    replace(module.eks.cluster_endpoint,"https://",""),
  ]
}

resource "aws_security_group" "sg_eks" {
  name   = "ACL EKS From SID"
  vpc_id = aws_vpc.sidera_cloud.id
  tags = {
    Name = "Admin access"
  }
  lifecycle {
    create_before_destroy = true
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = local.gui_access
  }

}

output "eks_cluster" {
  value = replace(module.eks.cluster_endpoint,"https://","")
}

locals {
  kubeconfig = <<KUBECONFIG


apiVersion: v1
clusters:
- cluster:
    server: https://${aws_route53_record.ekscname.fqdn}
    certificate-authority-data: ${module.eks.cluster_certificate_authority_data}
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: aws
  name: aws
current-context: aws
kind: Config
preferences: {}
users:
- name: aws
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1alpha1
      command: aws-iam-authenticator
      args:
        - "token"
        - "-i"
        - "${module.eks.cluster_name}"
KUBECONFIG
}

output "kubeconfig" {
  value = "${local.kubeconfig}"
}