output "vmseries0_ha2_ip" {
  value = aws_network_interface.ha2[0].private_ip
}

output "vmseries1_ha2_ip" {
  value = aws_network_interface.ha2[1].private_ip
}

output "vmseries0_ha2_gateway" {
  value = cidrhost(aws_subnet.ha2[0].cidr_block, 1)
}

output "vmseries1_ha2_gateway" {
  value = cidrhost(aws_subnet.ha2[1].cidr_block, 1)
}

output "vmseries0_mgmt_ip" {
  value = aws_network_interface.management[0].private_ip
}

output "vmseries1_mgmt_ip" {
  value = aws_network_interface.management[1].private_ip
}

output "vmseries0_mgmt_eip" {
  value = aws_eip.management[0].public_ip
}

output "vmseries1_mgmt_eip" {
  value = aws_eip.management[1].public_ip
}


output "floating_eip" {
  value = aws_eip.public[0].public_ip
}