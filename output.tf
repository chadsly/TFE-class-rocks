output "instance_ip_addr" {
  value = aws_instance.app.private_ip
}