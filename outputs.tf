output "Jumpbox_IP" {
  description = "The public IP address of the Jumpbox instance"
  value       = aws_eip.jumpbox_eip.public_ip
}

output "private_instance_ip" {
  description = "The private IP address of the private instance"
  value       = aws_instance.private_instance.private_ip
}