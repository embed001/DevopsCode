# Create security group with 4 rules
resource "tencentcloud_security_group" "web_sg" {
  name        = "web-sg"
  description = "make it accessible for both production and stage ports"
}

resource "tencentcloud_security_group_lite_rule" "all" {
  security_group_id = tencentcloud_security_group.web_sg.id

  ingress = [
    "ACCEPT#0.0.0.0/0#ALL#ALL"
  ]

  egress = [
    "ACCEPT#0.0.0.0/0#ALL#ALL"
  ]
}

# resource "tencentcloud_security_group_rule" "postgre_sql" {
#   security_group_id = tencentcloud_security_group.web_sg.id
#   type              = "ingress"
#   cidr_ip           = "0.0.0.0/0"
#   ip_protocol       = "tcp"
#   port_range        = "5432"
#   policy            = "accept"
# }

# resource "tencentcloud_security_group_rule" "ssh" {
#   security_group_id = tencentcloud_security_group.web_sg.id
#   type              = "ingress"
#   cidr_ip           = "0.0.0.0/0"
#   ip_protocol       = "tcp"
#   port_range        = "22"
#   policy            = "accept"
# }

resource "tencentcloud_security_group_rule" "web_egrees_any" {
  security_group_id = tencentcloud_security_group.web_sg.id
  type              = "egress"
  cidr_ip           = "0.0.0.0/0"
  policy            = "accept"
}
