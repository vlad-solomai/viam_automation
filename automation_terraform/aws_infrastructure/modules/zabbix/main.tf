terraform {
  required_version = ">= 0.12, < 0.13"
}

# Create zabbix virtual machine
resource "aws_instance" "zabbix" {
  count         = var.instance_count
  ami           = var.ami
  instance_type = var.instance_type
  key_name = "jenkins_aws"
  subnet_id = aws_subnet.private_subnet.id
  vpc_security_group_ids = [aws_security_group.private_subnet_sg.id]
  private_ip = "10.32.1.181"
  root_block_device  {

      volume_type = "gp2"
      volume_size = 50
      delete_on_termination = true
      tags = {
        Name = "zabbix${count.index + 1}-${var.environment}"
      }
    }

  tags = {
    Name = "zabbix${count.index + 1}-${var.environment}"
    Environment = "${var.environment}"
  }
}

resource "aws_route53_record" "zabbix" {
  zone_id = aws_route53_zone.dns_zone.zone_id
  name    = "zabbix-${var.domain_name}"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.zabbix.private_ip]
}

# create and associate elastic IP
resource "aws_eip" "zabbix_ip" {
  vpc = true
}

resource "aws_eip_association" "zabbix_eip_assoc" {
  instance_id   = aws_instance.zabbix.id
  allocation_id = aws_eip.zabbix_ip.id
}
