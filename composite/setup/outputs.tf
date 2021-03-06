# KMS
output "key_name" {
    value = module.kms.key_name
}

# VPC
output "public_subnet_cidr_blocks" {
    value = module.vpc.public_subnet_cidr_blocks
}
output "private_subnet_cidr_blocks" {
    value = module.vpc.private_subnet_cidr_blocks
}
output "public_subnet_ids" {
    value = module.vpc.public_subnet_ids
}
output "private_subnet_ids" {
    value = module.vpc.private_subnet_ids
}
output "vpc_id" {
    value = module.vpc.vpc_id
}

# Ansible Bastion
output "linux_mgmt_sg_id" {
    value = aws_security_group.linux_mgmt.id
}
output "winrm_mgmt_sg_id" {
    value = aws_security_group.winrm_mgmt.id
}
output "ansible_bastion_public_dns" {
    value = aws_eip.ansible-bastion.public_dns
}