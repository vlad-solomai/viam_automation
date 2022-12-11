terraform {
  required_version = ">= 0.12, < 0.13"
}

# Create proxy02 virtual machine
resource "aws_instance" "proxy02" {
  count         = var.instance_count
  ami           = var.ami
  instance_type = var.instance_type
  key_name = "jenkins_aws"
  subnet_id = aws_subnet.private_subnet.id
  vpc_security_group_ids = [aws_security_group.private_subnet_sg.id]
  private_ip = "10.32.1.13${count.index + 1}"
  root_block_device  {

      volume_type = "gp2"
      volume_size = 30
      delete_on_termination = true
      tags = {
        Name = "service-proxy${count.index + 1}-${var.environment}"
      }
    }

  tags = {
    Name = "service-proxy${count.index + 1}-${var.environment}"
    Environment = "${var.environment}"
  }
}

resource "aws_route53_record" "proxy02" {
  zone_id = aws_route53_zone.dns_zone.zone_id
  name    = "proxy02-${var.domain_name}"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.proxy02.private_ip]
}

resource "aws_route53_record" "wallet-so" {
  zone_id = aws_route53_zone.dns_zone.zone_id
  name    = "wallet-${var.domain_name}"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.proxy02.private_ip]
}

resource "aws_route53_record" "rng-so" {
  zone_id = aws_route53_zone.dns_zone.zone_id
  name    = "rng-${var.domain_name}"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.proxy02.private_ip]
}

resource "aws_route53_record" "engine-so" {
  zone_id = aws_route53_zone.dns_zone.zone_id
  name    = "engine-${var.domain_name}"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.proxy02.private_ip]
}

resource "aws_route53_record" "gameconfig-so" {
  zone_id = aws_route53_zone.dns_zone.zone_id
  name    = "gameconfig-${var.domain_name}"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.proxy02.private_ip]
}
