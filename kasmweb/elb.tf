resource "aws_lb" "kasm-alb" {
  name               = "kasmweb-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.kasm-default-elb-sg.id]
  subnets            = aws_subnet.sc_kasm_lb.*.id
  preserve_host_header = true

}

resource "aws_lb_target_group" "kasm-target-group" {
  name     = "kasmweb-target-group"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = data.aws_vpc.vpc.id

  health_check {
    path                = "/api/__healthcheck"
    matcher             = 200
    protocol            = "HTTPS"
  }
}

resource "aws_lb_listener" "kasm-alb-listener" {
  load_balancer_arn = aws_lb.kasm-alb.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   =  aws_acm_certificate.cert.arn

   default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.kasm-target-group.arn
  }
}

resource "aws_lb_target_group_attachment" "kasm-target-group-attachment" {
  //count            = "${var.num_webapps}"
  //target_id        = aws_instance.kasm-web-app[count.index].id
  target_group_arn = aws_lb_target_group.kasm-target-group.arn
  target_id        = aws_instance.kasm-web-app.id
  port             = 443
}

resource "aws_route53_record" "kasm-route53-elb-record" {
  count = var.private_zone_id != "" ? 1 : 0 
  zone_id = var.private_zone_id
  name    = "kasm-lb"
  type    = "A"

  alias {
    name                   = aws_lb.kasm-alb.dns_name
    zone_id                = aws_lb.kasm-alb.zone_id
    evaluate_target_health = true
  }
}


output "lb_dnsname" {
    value = aws_lb.kasm-alb.dns_name
}
output "debug" {
    value = aws_lb.kasm-alb.subnet_mapping
}