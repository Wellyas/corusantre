resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

/* resource "local_sensitive_file" "ssh_key" {
  filename = "${path.module}/.ssh/id_rsa"
  directory_permission = "0700"
  file_permission      = "0600"
  depends_on = [
    tls_private_key.ssh_key
  ]
  content = tls_private_key.ssh_key.private_key_openssh
}

resource "local_file" "ssh_pub" {
  filename = "${path.module}/.ssh/id_rsa.pub"
  directory_permission = "0750"
  file_permission      = "0640"
  depends_on = [
    tls_private_key.ssh_key
  ]
  content = tls_private_key.ssh_key.public_key_openssh
} */

resource "aws_key_pair" "ssh" {
  key_name = "terraform-deployer"
  public_key = tls_private_key.ssh_key.public_key_openssh
}


output "ssh_privkey" {
  value = tls_private_key.ssh_key.private_key_openssh
  description = "Credentials infos "
  sensitive = true
  depends_on = [
    tls_private_key.ssh_key
  ]
}