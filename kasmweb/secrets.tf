resource "random_password" "database" {
  length           = 26
  special          = true
  override_special = "_,"
}
resource "random_password" "redis" {
  length           = 26
  special          = true
  override_special = "_,"
}
resource "random_password" "user" {
  length           = 26
  special          = true
  override_special = "_,"
}
resource "random_password" "admin" {
  length           = 26
  special          = true
  override_special = "_,"
}

resource "random_password" "manager" {
  length           = 26
  special          = true
  override_special = "_,"
}