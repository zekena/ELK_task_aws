output "es-master" {
  value = aws_instance.es-master.public_ip
  description = "public IP of es-master node"
}

output "logstash" {
  value = aws_instance.logstash.public_ip
  description = "public IP of logstash node"
}

output "kibana" {
  value = aws_instance.kibana.public_ip
  description = "public IP of kibana node"
}
