output "vpc_id" {
  value = aws_vpc.default.id
}

output "nat_ips" {
  value = ["${aws_eip.nat_eip[*].public_ip}"]
}

output "public_subnet_ids" {
  value = ["${aws_subnet.public_default[*].id}"]
}

output "private_subnet_ids" {
  value = ["${aws_subnet.private_default[*].id}"]
}