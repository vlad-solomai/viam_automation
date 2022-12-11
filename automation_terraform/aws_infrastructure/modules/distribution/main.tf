terraform {
  required_version = ">= 0.12, < 0.13"
}

# Create distribution instances
resource "aws_instance" "distribution" {
  count         = var.instance_count
  ami           = var.ami
  instance_type = var.instance_type
  key_name = "jenkins_aws"
  subnet_id = aws_subnet.private_subnet.id
  vpc_security_group_ids = [aws_security_group.private_subnet_sg.id]
  private_ip = "10.32.1.10${count.index + 1}"
  root_block_device  {

      volume_type = "gp2"
      volume_size = 30
      delete_on_termination = true
      tags = {
        Name = "ds${count.index + 1}-${var.environment}"
      }
    }

  tags = {
    Name = "ds${count.index + 1}-${var.environment}"
    Environment = "${var.environment}"
  }
}

resource "aws_route53_record" "distribution" {
  zone_id = aws_route53_zone.dns_zone.zone_id
  name    = "ds0${count.index + 1}-${var.domain_name}"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.distribution.private_ip]
}
