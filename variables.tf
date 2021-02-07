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
  default = "~/.ssh/Keypair.pub"
}

variable "private_key_path" {
  description = "private key path to connect without password"
  default = "~/.ssh/Keypair"
}

variable "private_ip_es_master" {
  description = "private ip for es-master instance"
  default = "10.0.0.9"
}

variable "private_ip_logstash" {
  description = "private ip for instance that has logstash and es-data"
  default = "10.0.0.10"
}

variable "private_ip_kibana" {
  description = "private ip for instance that has kibana and es-data"
  default = "10.0.0.11"
}

variable "ssh_user" {
  default = "ubuntu"
}
