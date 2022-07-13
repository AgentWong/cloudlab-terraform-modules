resource "aws_security_group" "instance" {
  name   = "${var.prefix_name}-ansible-bastion"
  vpc_id = module.vpc.vpc_id
}
resource "aws_security_group_rule" "icmp_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.instance.id

  from_port   = -1
  to_port     = -1
  protocol    = "icmp"
  cidr_blocks = var.linux_mgmt_cidr
}
resource "aws_security_group_rule" "ssh_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.instance.id

  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = var.linux_mgmt_cidr
}
resource "aws_security_group_rule" "allow_all_outbound" {
  type              = "egress"
  security_group_id = aws_security_group.instance.id

  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group" "linux_mgmt" {
  name   = "${var.prefix_name}-linux-mgmt"
  vpc_id = module.vpc.vpc_id
}
resource "aws_security_group_rule" "ssh_mgmt_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.linux_mgmt.id

  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  source_security_group_id = aws_security_group.instance.id
}
resource "aws_security_group" "winrm_mgmt" {
  name   = "${var.prefix_name}-winrm-mgmt"
  vpc_id = module.vpc.vpc_id
}
resource "aws_security_group_rule" "winrm_mgmt_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.winrm_mgmt.id

  from_port   = 5985
  to_port     = 5986
  protocol    = "tcp"
  source_security_group_id = aws_security_group.instance.id
}