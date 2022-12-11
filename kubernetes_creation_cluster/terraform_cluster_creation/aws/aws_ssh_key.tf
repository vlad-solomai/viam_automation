resource "aws_key_pair" "kuber_key" {
  key_name   = "kub-sys-node"
  public_key = file("kubespray.pub")
}
