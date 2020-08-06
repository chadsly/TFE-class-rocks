output "instance_ip_addr" {
  value = aws_instance.app[count.index].private_ip
}