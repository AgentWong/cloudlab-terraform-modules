locals {
  instance_name = toset([for i in range(1, var.instance_count + 1) : format("%s-%02d", var.instance_name, i)])
}
resource "aws_instance" "this" {
  for_each                    = local.instance_name
  ami                         = data.aws_ami.instance.id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  get_password_data           = var.get_password_data
  vpc_security_group_ids      = var.security_group_ids
  subnet_id                   = var.subnet_id
  user_data                   = var.user_data
  associate_public_ip_address = var.associate_public_ip_address
  tags = {
    Name             = "${each.value}"
    Operating_System = "${var.operating_system}"
  }
}
