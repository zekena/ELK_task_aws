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

variable "ami" {
  default = "ami-0502e817a62226e03"
}

variable "instance_type" {
  default = "t2.medium"
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
  default = "/home/zkenawi/.ssh/id_rsa.pub"
}

variable "private_key_path" {
  description = "private key path to connect without password"
  default = "/home/zkenawi/.ssh/id_rsa"
}

variable "private_ip_es_master" {
  description = "private ip for es-master instance"
  default = "10.0.0.4"
}

variable "private_ip_logstash" {
  description = "private ip for instance that has logstash and es-data"
  default = "10.0.0.5"
}

variable "private_ip_kibana" {
  description = "private ip for instance that has kibana and es-data"
  default = "10.0.0.6"
}

variable "ssh_user" {
  default = "ubuntu"
}
