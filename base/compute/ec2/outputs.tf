output "instance_ids" {
  value = values(aws_instance.this)[*].id
}
output "instance_names" {
  value = values(aws_instance.this)[*].tags["Name"]
}
output "public_ips" {
  value = values(aws_instance.this)[*].public_ip
}
output "primary_network_interface_ids" {
  value = values(aws_instance.this)[*].primary_network_interface_id
}
output "private_ips" {
  value = values(aws_instance.this)[*].private_ip
}
output "password_data" {
  value = values(aws_instance.this)[*].password_data
}
