provider "aws" {
  region                  = var.region
  shared_credentials_file = var.credentials
  profile                 = var.profile
}


module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "main"
  cidr = var.cidr_blocks

  azs            = ["${var.region}a"]
  public_subnets = var.public_subnets

  enable_nat_gateway = true

  tags = {
    Environment = "dev"
  }
}

resource "aws_security_group" "ssh" {
  name        = "default-ssh-example"
  description = "Security group for nat instances that allows SSH and VPN traffic from internet"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ssh-example-default-vpc"
  }
}

resource "aws_instance" "es-master" {
  ami             = "ami-0502e817a62226e03"
  instance_type   = "t2.micro"
  key_name        = aws_key_pair.public_key.key_name
  security_groups = [aws_security_group.instance.id]

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
}
