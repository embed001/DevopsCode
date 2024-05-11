output "harbor_url" {
  value = "https://harbor.${var.prefix}.${var.domain}, admin, Harbor12345"
}

output "argocd_url" {
  value = "http://argocd.${var.prefix}.${var.domain}, admin, password123"
}

output "jenkins_url" {
  value = "http://jenkins.${var.prefix}.${var.domain}, admin, password123"
}

output "jira_url" {
  value = "http://jira.${var.prefix}.${var.domain}, (Not ready, need to setup)"
}

output "sonar_url" {
  value = "http://sonar.${var.prefix}.${var.domain}, admin, password123"
}
