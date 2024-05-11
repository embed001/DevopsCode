module "harbor" {
  source     = "./harbor"
  prefix     = var.prefix
  domain     = var.domain
  secret_id  = var.secret_id
  secret_key = var.secret_key
}

module "jenkins" {
  source                = "./jenkins"
  prefix                = var.prefix
  domain                = var.domain
  secret_id             = var.secret_id
  secret_key            = var.secret_key
  github_username       = var.github_username
  github_personal_token = var.github_personal_token
}

module "jira" {
  source     = "./jira"
  prefix     = var.prefix
  domain     = var.domain
  secret_id  = var.secret_id
  secret_key = var.secret_key
}
