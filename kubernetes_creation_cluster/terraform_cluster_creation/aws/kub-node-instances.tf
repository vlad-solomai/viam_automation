resource "aws_instance" "kube-node" {
  count           = var.instance_count["kub-node-count"]
  ami             = var.ami["kub-node-ami"]
  instance_type   = var.instance_type["kub-node-count-instance_type"]
  key_name        = aws_key_pair.kuber_key.key_name
  security_groups = [aws_security_group.allow_all.name]

  tags = {
    Name  = "kubworker-${count.index + 1}"
  }
}
