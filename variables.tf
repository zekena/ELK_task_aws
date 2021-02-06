variable "region" {
  description = "region of IAM user"
  default = "eu-central-1"
}

variable "credentials" {
  description = "credentials for IAM user"
  default = "~/.aws/credentials"
}

variable "profile" {
  description = "IAM user profile name"
  default = "zekena"
}

variable "cidr_blocks" {
  description = "cidr blocks of VPC"
  default = "10.0.0.0/18"
}

variable "private_subnets" {
  default = "10.0.1.0/24"
}

variable "public_subnets" {
  default = "10.0.0.0/24"
}

variable "public_key_path" {
  description = "public key in order to place it in the ec2 instance"
  default = "~/.ssh/id_rsa.pub"
}

variable "private_key_path" {
  description = "private key path to connect without password"
  default = "~/.ssh/id_rsa"
}

variable "private_ip_es_master" {
  description = "private ip for es-master instance"
  default = "10.0.1.1"
}

variable "private_ip_logstash" {
  description = "private ip for instance that has logstash and es-data"
  default = "10.0.1.2"
}

variable "private_ip_kibana" {
  description = "private ip for instance that has kibana and es-data"
  default = "10.0.1.3"
}

variable "ssh_user" {
  default = "ubuntu"
}
