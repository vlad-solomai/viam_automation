resource "aws_instance" "kube-master" {
  count           = var.instance_count["kub-master-count"]
  ami             = var.ami["kub-master-ami"]
  instance_type   = var.instance_type["kub-master-instance_type"]
  key_name        = aws_key_pair.kuber_key.key_name
  security_groups = [aws_security_group.allow_all.name]

  tags = {
    Name  = "kubmaster-${count.index + 1}"
  }
}
