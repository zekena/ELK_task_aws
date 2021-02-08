provider "aws" {
  region                  = var.region
  shared_credentials_file = var.credentials
  profile                 = var.profile
}


module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "main"
  cidr = var.cidr_blocks

  azs             = ["${var.region}a"]
  private_subnets = [var.private_subnets]
  public_subnets  = [var.public_subnets]

  enable_nat_gateway = true

  tags = {
    Environment = "dev"
  }
}

resource "aws_security_group" "kibana" {
  name        = "kibana-server"
  description = "make the kibana server open for the public access"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 9300
    protocol        = "tcp"
    security_groups = [aws_security_group.ssh.id]
    to_port         = 9300
  }
  ingress {
    from_port       = 9200
    protocol        = "tcp"
    security_groups = [aws_security_group.ssh.id]
    to_port         = 9200
  }
  ingress {
    from_port   = 5601
    to_port     = 5601
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Kibana-port"
  }
}

resource "aws_security_group" "logstash" {
  name        = "logstash-server"
  description = "make logstash server open for access to other servers"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 9300
    protocol        = "tcp"
    security_groups = [aws_security_group.ssh.id]
    to_port         = 9300
  }
  ingress {
    from_port       = 9200
    protocol        = "tcp"
    security_groups = [aws_security_group.ssh.id]
    to_port         = 9200
  }

  tags = {
    Name = "logstash-entry"
  }
}

resource "aws_security_group" "es-master" {
  name        = "es-master-server"
  description = "make es-master server open for access to other servers"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 9300
    protocol        = "tcp"
    security_groups = [aws_security_group.ssh.id]
    to_port         = 9300
  }
  ingress {
    from_port       = 9200
    protocol        = "tcp"
    security_groups = [aws_security_group.ssh.id]
    to_port         = 9200
  }

  tags = {
    Name = "es-master-entry"
  }
}
resource "aws_security_group" "ssh" {
  name        = "default-ssh-group"
  description = "Security group for nat instances that allows SSH traffic from internet"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ssh-example-default-vpc"
  }
}

resource "aws_key_pair" "keys" {
  key_name   = "personal_key"
  public_key = file(var.public_key_path)
}

resource "aws_instance" "es-master" {
  ami             = var.ami
  instance_type   = var.instance_type
  key_name        = aws_key_pair.keys.key_name
  security_groups = [aws_security_group.ssh.id]

  provisioner "remote-exec" {
    inline = ["sudo apt update && sudo apt install python3 -y"]

    connection {
      type        = "ssh"
      user        = var.ssh_user
      private_key = file(var.private_key_path)
      host        = aws_instance.es-master.public_ip
    }
  }

  provisioner "local-exec" {
    command = "ssh-keyscan -H ${aws_instance.es-master.public_ip} >> ~/.ssh/known_hosts;ansible-playbook -u ${var.ssh_user} -i ${aws_instance.es-master.public_ip}, --private-key ${var.private_key_path} --extra-vars \"master_host=${var.private_ip_es_master} node_1_host=${var.private_ip_logstash} node_2_host=${var.private_ip_kibana} host_ip=${var.private_ip_es_master}\" --vault-password-file ${var.vault_password} -t es-master main.yaml"
  }

  subnet_id                   = element(module.vpc.public_subnets, 0)
  associate_public_ip_address = true
  private_ip                  = var.private_ip_es_master
  tags = {
    Name = "es-master"
  }
}

resource "aws_instance" "logstash" {
  ami             = var.ami
  instance_type   = var.instance_type
  key_name        = aws_key_pair.keys.key_name
  security_groups = [aws_security_group.ssh.id]

  provisioner "remote-exec" {
    inline = ["sudo apt update && sudo apt install python3 -y"]

    connection {
      type        = "ssh"
      user        = var.ssh_user
      private_key = file(var.private_key_path)
      host        = aws_instance.logstash.public_ip
    }
  }

  provisioner "local-exec" {
    command = "ssh-keyscan -H ${aws_instance.logstash.public_ip} >> ~/.ssh/known_hosts;ansible-playbook -u ${var.ssh_user} -i ${aws_instance.logstash.public_ip}, --private-key ${var.private_key_path} --extra-vars \"master_host=${var.private_ip_es_master} node_1_host=${var.private_ip_logstash} node_2_host=${var.private_ip_kibana} host_ip=${var.private_ip_logstash}\" --vault-password-file ${var.vault_password} -t logstash main.yaml"
  }
  subnet_id                   = element(module.vpc.public_subnets, 0)
  associate_public_ip_address = true
  private_ip                  = var.private_ip_logstash
  tags = {
    Name = "logstash"
  }
}

resource "aws_instance" "kibana" {
  ami             = var.ami
  instance_type   = var.instance_type
  key_name        = aws_key_pair.keys.key_name
  security_groups = [aws_security_group.ssh.id, aws_security_group.kibana.id]

  provisioner "remote-exec" {
    inline = ["sudo apt update && sudo apt install python3 -y"]

    connection {
      type        = "ssh"
      user        = var.ssh_user
      private_key = file(var.private_key_path)
      host        = aws_instance.kibana.public_ip
    }
  }

  provisioner "local-exec" {
    command = "ssh-keyscan -H ${aws_instance.kibana.public_ip} >> ~/.ssh/known_hosts;ansible-playbook -u ${var.ssh_user} -i ${aws_instance.kibana.public_ip}, --private-key ${var.private_key_path} --extra-vars \"master_host=${var.private_ip_es_master} node_1_host=${var.private_ip_logstash} node_2_host=${var.private_ip_kibana} host_ip=${var.private_ip_kibana}\" --vault-password-file ${var.vault_password} -t kibana main.yaml"
  }

  subnet_id                   = element(module.vpc.public_subnets, 0)
  associate_public_ip_address = true
  private_ip                  = var.private_ip_kibana
  tags = {
    Name = "kibana"
  }
}
