module "kms" {
  source = "../../base/compute/ec2-keypair"

  key_name   = var.key_name
  public_key = var.public_key
}
module "vpc" {
  source = "../../base/network/vpc"

  prefix_name     = var.prefix_name
  vpc_cidr        = var.vpc_cidr
  tgw_cidr        = var.tgw_cidr
  region          = var.region
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
}
module "ansible-bastion" {
  source = "../../base/compute/ec2"

  key_name                    = module.kms.key_name
  instance_name               = "ansible-bastion"
  instance_type               = "t2.micro"
  instance_count              = 1
  iam_instance_profile        = aws_iam_instance_profile.ansible_inventory_profile.name
  associate_public_ip_address = true
  ami_owner                   = "309956199498"
  ami_name                    = "RHEL-8*HVM*x86_64*GP2*"
  operating_system            = "Linux"
  region                      = var.region
  subnet_id                   = module.vpc.public_subnet_ids[0]
  vpc_id                      = module.vpc.vpc_id
  security_group_ids          = [aws_security_group.ansible_bastion.id]
  user_data                   = <<EOF
#!/bin/bash
yum update -y
yum install -y ansible git python3-pip python3-setuptools gcc python3-devel krb5-devel krb5-workstation
pip3 install wheel
pip3 install --upgrade requests
pip3 install pywinrm[kerberos] boto3
git clone https://github.com/AgentWong/cloudlab-ansible.git /home/ec2-user/ansible
ansible-galaxy collection install ansible.windows -p /usr/share/ansible/collections
ansible-galaxy collection install community.windows -p /usr/share/ansible/collections
chown -R ec2-user:ec2-user /home/ec2-user/ansible
EOF
}
resource "aws_eip" "ansible-bastion" {
  vpc                       = true
  network_interface         = module.ansible-bastion.primary_network_interface_ids[0]
  associate_with_private_ip = module.ansible-bastion.private_ips[0]
}
resource "null_resource" "copy_private_key" {
  triggers = {
    ansible_bastion_id = module.ansible-bastion.instance_ids[0]
  }

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("~/.ssh/id_rsa")
    host        = aws_eip.ansible-bastion.public_dns
  }

  provisioner "file" {
    source      = "~/.ssh/id_rsa"
    destination = "/home/ec2-user/.ssh/id_rsa"
  }
  provisioner "remote-exec" {
    inline = ["chmod 0600 /home/ec2-user/.ssh/id_rsa", "cloud-init status --wait"]
  }
  depends_on = [
    module.ansible-bastion
  ]
}
module "windows-bastion" {
  source = "../../base/compute/ec2"

  key_name                    = module.kms.key_name
  instance_name               = "windows-bastion"
  instance_type               = "t3.medium"
  instance_count              = 1
  associate_public_ip_address = true
  ami_owner                   = "amazon"
  ami_name                    = "Windows_Server-2019-English-Full-Base*"
  operating_system            = "Windows"
  region                      = var.region
  subnet_id                   = module.vpc.public_subnet_ids[0]
  vpc_id                      = module.vpc.vpc_id
  security_group_ids          = [aws_security_group.windows_bastion.id]
}
resource "aws_eip" "windows-bastion" {
  vpc                       = true
  network_interface         = module.windows-bastion.primary_network_interface_ids[0]
  associate_with_private_ip = module.windows-bastion.private_ips[0]
}

resource "aws_flow_log" "vpc_flow_log" {
  iam_role_arn    = aws_iam_role.vpc_flow_log.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_log.arn
  traffic_type    = "REJECT"
  vpc_id          = module.vpc.vpc_id
}
resource "aws_cloudwatch_log_group" "vpc_flow_log" {
  name = "vpc_flow_log"
}
resource "aws_iam_role" "vpc_flow_log" {
  name = "vpc_flow_log"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "vpc-flow-logs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}
resource "aws_iam_role_policy" "vpc_flow_log" {
  name = "vpc_flow_log"
  role = aws_iam_role.vpc_flow_log.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}
