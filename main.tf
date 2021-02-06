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

resource "aws_security_group" "ssh" {
  name        = "default-ssh-example"
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

resource "aws_instance" "es-master" {
  ami             = "ami-0502e817a62226e03"
  instance_type   = "t2.micro"
  key_name        = var.private_key_path
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

  subnet_id                   = element(module.vpc.public_subnets, 0)
  associate_public_ip_address = true
  private_ip                  = var.private_ip_es_master
}

resource "aws_instance" "logstash" {
  ami             = "ami-0502e817a62226e03"
  instance_type   = "t2.micro"
  key_name        = var.private_key_path
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

  subnet_id                   = element(module.vpc.public_subnets, 0)
  associate_public_ip_address = true
  private_ip                  = var.private_ip_logstash
}

resource "aws_instance" "kibana" {
  ami             = "ami-0502e817a62226e03"
  instance_type   = "t2.micro"
  key_name        = var.private_key_path
  security_groups = [aws_security_group.ssh.id]

  provisioner "remote-exec" {
    inline = ["sudo apt update && sudo apt install python3 -y"]

    connection {
      type        = "ssh"
      user        = var.ssh_user
      private_key = file(var.private_key_path)
      host        = aws_instance.kibana.public_ip
    }
  }

  subnet_id                   = element(module.vpc.public_subnets, 0)
  associate_public_ip_address = true
  private_ip                  = var.private_ip_kibana
}
