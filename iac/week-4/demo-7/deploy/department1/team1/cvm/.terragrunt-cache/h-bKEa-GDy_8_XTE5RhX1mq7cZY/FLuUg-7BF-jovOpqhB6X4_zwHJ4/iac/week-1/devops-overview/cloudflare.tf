provider "cloudflare" {
  api_token = var.cloudflare_api_key
}

data "cloudflare_zone" "this" {
  name = var.domain
}

resource "cloudflare_record" "gitlab" {
  zone_id         = data.cloudflare_zone.this.id
  name            = "gitlab.${var.prefix}.${var.domain}"
  value           = tencentcloud_instance.ubuntu[0].public_ip
  type            = "A"
  ttl             = 60
  allow_overwrite = true
}

resource "cloudflare_record" "harbor" {
  zone_id         = data.cloudflare_zone.this.id
  name            = "harbor.${var.prefix}.${var.domain}"
  value           = tencentcloud_instance.ubuntu[0].public_ip
  type            = "A"
  ttl             = 60
  allow_overwrite = true
}

resource "cloudflare_record" "jenkins" {
  zone_id         = data.cloudflare_zone.this.id
  name            = "jenkins.${var.prefix}.${var.domain}"
  value           = tencentcloud_instance.ubuntu[0].public_ip
  type            = "A"
  ttl             = 60
  allow_overwrite = true
}

resource "cloudflare_record" "sonar" {
  zone_id         = data.cloudflare_zone.this.id
  name            = "sonar.${var.prefix}.${var.domain}"
  value           = tencentcloud_instance.ubuntu[0].public_ip
  type            = "A"
  ttl             = 60
  allow_overwrite = true
}

resource "cloudflare_record" "argocd" {
  zone_id         = data.cloudflare_zone.this.id
  name            = "argocd.${var.prefix}.${var.domain}"
  value           = tencentcloud_instance.ubuntu[0].public_ip
  type            = "A"
  ttl             = 60
  allow_overwrite = true
}

resource "cloudflare_record" "grafana" {
  zone_id         = data.cloudflare_zone.this.id
  name            = "grafana.${var.prefix}.${var.domain}"
  value           = tencentcloud_instance.ubuntu[0].public_ip
  type            = "A"
  ttl             = 60
  allow_overwrite = true
}

resource "cloudflare_record" "prometheus" {
  zone_id         = data.cloudflare_zone.this.id
  name            = "prometheus.${var.prefix}.${var.domain}"
  value           = tencentcloud_instance.ubuntu[0].public_ip
  type            = "A"
  ttl             = 60
  allow_overwrite = true
}
