data "http" "myip" {
  url = "https://api.ipify.org"
}

locals {
  my_ip = "${tostring(data.http.myip.body)}/32"
}

output "my_ip" {
  value = local.my_ip
}