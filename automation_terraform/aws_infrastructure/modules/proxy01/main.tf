terraform {
  required_version = ">= 0.12, < 0.13"
}

# Create proxy01 virtual machine
resource "aws_instance" "proxy01" {
  count         = var.instance_count
  ami           = var.ami
  instance_type = var.instance_type
  key_name = "jenkins_aws"
  subnet_id = aws_subnet.private_subnet.id
  vpc_security_group_ids = [aws_security_group.public_subnet_sg.id, aws_security_group.public_subnet_https_sg.id]
  private_ip = "10.32.0.10${count.index + 1}"
  root_block_device  {

      volume_type = "gp2"
      volume_size = 30
      delete_on_termination = true
      tags = {
        Name = "web-proxy${count.index + 1}-${var.environment}"
      }
    }

  tags = {
    Name = "web-proxy${count.index + 1}-${var.environment}"
    Environment = "${var.environment}"
  }
}

resource "aws_route53_record" "proxy01" {
  zone_id = aws_route53_zone.dns_zone.zone_id
  name    = "proxy0${count.index + 1}-${var.domain_name}"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.proxy01.private_ip]
}

# create and associate elastic IP
resource "aws_eip" "proxy01_ip" {
  vpc = true
}

resource "aws_eip_association" "proxy01_eip_assoc" {
  instance_id   = aws_instance.proxy01.id
  allocation_id = aws_eip.proxy01_ip.id
}
