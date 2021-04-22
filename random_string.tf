resource "random_string" "unique_id" {
  lower   = true
  upper   = false
  special = false
  number  = false
  length  = 4
}