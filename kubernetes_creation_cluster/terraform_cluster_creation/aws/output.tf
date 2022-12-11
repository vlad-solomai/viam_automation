output "public-nodes-ip" {
  value = aws_instance.kube-node.*.public_ip
}

output "private-nodes-ip" {
  value = aws_instance.kube-node.*.private_ip
}

output "public-masters-ip" {
   value = aws_instance.kube-master.*.public_ip
}

output "private-masters-ip" {
  value = aws_instance.kube-master.*.private_ip
}
