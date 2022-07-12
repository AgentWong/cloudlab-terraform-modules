locals {
  instance_name = "${var.environment}-DC-01"
}
module "pdc" {
  source = "../../base/compute/ec2"

  key_name                    = module.kms.key_name
  instance_name               = local.instance_name
  instance_type               = "t3.medium"
  instance_count              = 1
  iam_instance_profile        = aws_iam_instance_profile.ansible_inventory_profile.name
  associate_public_ip_address = true
  ami_owner                   = "amazon"
  ami_name                    = "Windows_Server-2019-English-Full-Base*"
  operating_system            = "Windows"
  region                      = var.region
  subnet_id                   = module.vpc.private_subnets[0]
  vpc_id                      = module.vpc.vpc_id
  security_group_ids          = [aws_security_group.instance.id, var.ansible_winrm_sg_id]
}
module "secrets" {
  source = "../../../base/secrets-manager"

  names = ["radmin"]
  path  = var.path
}

data "aws_secretsmanager_secret_version" "radmin_password" {
  secret_id = module.secrets.secret_ids[0]
}
resource "null_resource" "ansible_pdc" {
  triggers = {
    ansible_bastion_id = module.pdc.instance_ids[0]
  }

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("~/.ssh/id_rsa")
    host        = aws_eip.ansible-bastion.public_dns
  }

  provisioner "remote-exec" {
    inline = templatefile("${path.module}/../../../../run_playbook.tftpl",{
      ansible_password = rsadecrypt(module.pdc.password_data[0],file("~/.ssh/id_rsa"))
      vars = {
        amazon_dns = "${regex("\\b(?:\\d{1,3}.){1}\\d{1,3}\\b",module.pdc.private_ip[0])}.0.2"
        pdc_hostname = module.pdc.private_ip[0]
        domain = var.domain_name #valhalla.local
        netbios = var.netbios #VALHALLA
        password = data.aws_secretsmanager_secret_version.radmin_password.secret_string
        reverse_lookup_zone = "${strrev(regex("\\b(?:\\d{1,3}.){2}\\d{1,3}\\b",module.pdc.private_ip[0]))}.in-addr.arpa"
      }
    })
  }
  depends_on = [
    module.pdc
  ]
}