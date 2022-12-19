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
  route_table_id = aws_route_table.natgw.id
}

locals {
  cluster_name = "sidera-eks-${random_string.suffix.result}"
  cluster_version = "1.24"
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
        aws_security_group.sg_admin_from_wab.id
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

output "eks_cluster" {
  value = replace(module.eks.cluster_endpoint,"https://","")
}