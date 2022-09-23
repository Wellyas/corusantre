
variable "agent_instance_type" {
  default     = "t3.medium"
  description = "The instance type for the Agents"
}
variable "webapp_instance_type" {
  default     = "t3.small"
  description = "The instance type for the webapps"
}
variable "db_instance_type" {
  default     = "t3.small"
  description = "The instance type for the Database"
}
variable "ec2_ami" {
  default     = "ami-0f7559f51d3a22167"
  description = "The AMI used for the EC2 nodes. Recommended Ubuntu 18.04 LTS."
}
variable "kasm_build" {
  description = "The URL for the Kasm Workspaces build"
  default = "https://kasm-static-content.s3.amazonaws.com/kasm_release_1.11.0.18142e.tar.gz"
}
variable "zone_name" {
  default = "default"
  description="A name given to the kasm deployment Zone"
}

variable "ssh_access_cidr" {
  default     = "0.0.0.0/0"
  description = "CIDR notation of the bastion host allowed to SSH in to the machines"
}

variable "key_name" {
  description = "The name of an aws keypair to use."
}

variable "vpc_id" {
  description = "The virtual private cloud ID to be attach to"
}

variable "internet_gateway_id" {
  description = "The virtual private cloud ID to be attach to"
}

variable "private_zone_id" {
  default = ""
  description = "Id of the virtual private Zone for dns entries"
}

variable "vpn_fw_oam" {
  default = ""
  description = "the vpn gateway for oam tunnel"
}
variable "num_agents" {
  default     = "2"
  description = "The number of Agent Role Servers to create in the deployment"
}

variable "https_access_cidr" {
  default = ["0.0.0.0/0"]
  description = "List of CIDR notation of allowed host to access HTTPS"
}


variable "proxies_servers_cidr" {
  default = ["0.0.0.0/0"]
  description = "List of CIDR notation of proxies server to allow agent to go"
}