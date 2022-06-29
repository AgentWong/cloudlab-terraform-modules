terraform {
  source = "../../../../modules//base/ec2"
}
include "root" {
  path = find_in_parent_folders()
}
dependency "vpc" {
  config_path = "../network/vpc"
}
inputs = {
  public_subnets = dependency.vpc.public_subnets
  vpc_id         = dependency.vpc.vpc_id
  user_data      = <<EOF
    #!/bin/bash
    yum -y install httpd git
    service httpd start
    echo "This is coming from default apache page" >> /var/www/html/index.html
    cd
    git clone https://github.com/PacktPublishing/Mastering-AWS-System-Administration.git
    cd Mastering-AWS-System-Administration/Chapter4-Scalable-compute-capacity-in-the-cloud-via-EC2/html/
    cp -avr work /var/www/html/
    EOF
}
