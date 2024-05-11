provider "cloudflare" {
  api_token = var.cloudflare_api_key
}

data "cloudflare_zone" "this" {
  name = var.domain
}

resource "cloudflare_record" "gitlab" {
  zone_id         = data.cloudflare_zone.this.id
  name            = "gitlab.${var.domain}"
  value           = "public_ip"
  type            = "A"
  ttl             = 60
  allow_overwrite = true
}

resource "cloudflare_record" "harbor" {
  zone_id         = data.cloudflare_zone.this.id
  name            = "harbor.${var.domain}"
  value           = "192.168.31.176"
  type            = "A"
  ttl             = 60
  allow_overwrite = true
}

resource "cloudflare_record" "jenkins" {
  zone_id         = data.cloudflare_zone.this.id
  name            = "jenkins.${var.domain}"
  value           = "192.168.31.176"
  type            = "A"
  ttl             = 60
  allow_overwrite = true
}

resource "cloudflare_record" "sonar" {
  zone_id         = data.cloudflare_zone.this.id
  name            = "sonar.${var.domain}"
  value           = "192.168.31.176"
  type            = "A"
  ttl             = 60
  allow_overwrite = true
}

resource "cloudflare_record" "argocd" {
  zone_id         = data.cloudflare_zone.this.id
  name            = "argocd.${var.domain}"
  value           = "192.168.31.176"
  type            = "A"
  ttl             = 60
  allow_overwrite = true
}

resource "cloudflare_record" "grafana" {
  zone_id         = data.cloudflare_zone.this.id
  name            = "grafana.${var.domain}"
  value           = "192.168.31.176"
  type            = "A"
  ttl             = 60
  allow_overwrite = true
}

resource "cloudflare_record" "prometheus" {
  zone_id         = data.cloudflare_zone.this.id
  name            = "prometheus.${var.domain}"
  value           = "192.168.31.176"
  type            = "A"
  ttl             = 60
  allow_overwrite = true
}
