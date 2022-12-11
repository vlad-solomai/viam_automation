terraform {
  required_version = ">= 0.12, < 0.13"
}

# Create win01 virtual machine
resource "aws_instance" "engine" {
  count         = var.instance_count
  ami           = var.ami
  instance_type = var.instance_type
  key_name = "jenkins_aws"
  subnet_id = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.public_subnet_sg.id, aws_security_group.public_subnet_https_sg.id, aws_security_group.public_subnet_rdp_sg.id]
  private_ip = "10.32.0.11${count.index + 1}"
  get_password_data = true
  root_block_device  {
      volume_type = "gp2"
      volume_size = 150
      delete_on_termination = true
      tags = {
        Name = "win${count.index + 1}-${var.environment}"
      }
    }

  tags = {
    Name = "win${count.index + 1}-${var.environment}"
    Environment = "${var.environment}"
  }
}

resource "aws_route53_record" "engine" {
  zone_id = aws_route53_zone.dns_zone.zone_id
  name    = "win0${count.index + 1}-${var.domain_name}"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.engine.private_ip]
}

# create and associate elastic IP
resource "aws_eip" "win_IP" {
  vpc = true
}

resource "aws_eip_association" "win_eip_assoc" {
  instance_id   = aws_instance.win.id
  allocation_id = aws_eip.win_IP.id
}
