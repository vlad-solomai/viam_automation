terraform {
  required_version = ">= 0.12, < 0.13"
}

# Create bastion virtual machine
resource "aws_instance" "bastion" {
  count         = var.instance_count
  ami           = var.ami
  instance_type = var.instance_type
  key_name = "jenkins_aws"
  subnet_id = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.public_subnet_sg.id, aws_security_group.public_subnet_ssh_sg.id]
  private_ip = "10.32.0.121"
  root_block_device  {
      volume_type = "gp2"
      volume_size = 30
      delete_on_termination = true
      tags = {
        Name = "jump${count.index + 1}-${var.environment}"
      }
    }

  tags = {
    Name = "jump${count.index + 1}-${var.environment}"
    Environment = "${var.environment}"
  }
}

resource "aws_route53_record" "bastion" {
  zone_id = aws_route53_zone.dns_zone.zone_id
  name    = "jump-${var.domain_name}"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.bastion.private_ip]
}

# create and associate elastic IP
resource "aws_eip" "bastion_ip" {
  vpc = true
}

resource "aws_eip_association" "bastion_eip_assoc" {
  instance_id   = aws_instance.bastion.id
  allocation_id = aws_eip.bastion_ip.id
}
