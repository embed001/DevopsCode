module "pg" {
  source     = "./pg"
  secret_id  = var.secret_id
  secret_key = var.secret_key
}

resource "null_resource" "connect_ubuntu" {
  connection {
    host     = tencentcloud_instance.ubuntu[0].public_ip
    type     = "ssh"
    user     = "ubuntu"
    password = var.password
    //private_key = file("ssh-key/id_rsa")
    //agent = false
  }

  triggers = {
    script_hash = filemd5("${path.module}/init.sh.tpl")
  }

  // init.sh
  provisioner "file" {
    destination = "/tmp/init.sh"
    content = templatefile(
      "${path.module}/init.sh.tpl",
      {
        "public_ip" : "${tencentcloud_instance.ubuntu[0].public_ip}"
        "domain" : "${var.prefix}.${var.domain}",
        "gitlab_host" : "https://gitlab.${var.prefix}.${var.domain}"
        "harbor_registry" : "${var.registry}"
        "harbor_password" : "${var.harbor_password}"
        "example_project_name" : "${var.example_project_name}"
        "sonar_password" : "${var.sonar_password}"
        "grafana_password" : "${var.grafana_password}"
        "jenkins_password" : "${var.jenkins_password}"
        "argocd_password" : "${var.argocd_password}"
        "pg_ip" : "${module.pg.public_ip}"
        "pg_password" : "${var.pg_password}"
      }
    )
  }

  # kube-prometheus-stack
  provisioner "file" {
    destination = "/tmp/kube-prometheus-stack-values.yaml"
    content = templatefile(
      "${path.module}/prometheus/values.yaml.tpl",
      {
        "domain" : "${var.prefix}.${var.domain}"
        "grafana_password" : "${var.grafana_password}"
      }
    )
  }

  # jenkins
  provisioner "file" {
    source      = "jenkins/dashboard.yaml"
    destination = "/tmp/jenkins-dashboard.yaml"
  }

  provisioner "file" {
    destination = "/tmp/jenkins-values.yaml"
    content = templatefile(
      "${path.module}/jenkins/values.yaml.tpl",
      {
        "domain" : "${var.prefix}.${var.domain}"
        "jenkins_password" : "${var.jenkins_password}"
      }
    )
  }

  provisioner "file" {
    destination = "/tmp/jenkins-harbor-url-secret.yaml"
    content = templatefile(
      "${path.module}/jenkins/harbor-url-secret.yaml.tpl",
      {
        "domain" : "${var.prefix}.${var.domain}"
      }
    )
  }

  provisioner "file" {
    destination = "/tmp/harbor-repository-secret.yaml"
    content = templatefile(
      "${path.module}/jenkins/harbor-repository-secret.yaml.tpl",
      {
        "harbor_registry" : "${var.registry}"
      }
    )
  }

  provisioner "file" {
    source      = "jenkins/github-pull-secret.yaml"
    destination = "/tmp/github-pull-secret.yaml"
  }

  # provisioner "file" {
  #   source      = "jenkins/dockerhub-secret.yaml"
  #   destination = "/tmp/dockerhub-secret.yaml"
  # }

  provisioner "file" {
    source      = "jenkins/service-account.yaml"
    destination = "/tmp/jenkins-service-account.yaml"
  }

  // sonarqube
  provisioner "file" {
    destination = "/tmp/sonarqube-values.yaml"
    content = templatefile(
      "${path.module}/sonarqube/values.yaml.tpl",
      {
        "domain" : "${var.prefix}.${var.domain}"
        "sonar_password" : "${var.sonar_password}"
      }
    )
  }

  provisioner "file" {
    source      = "sonarqube/sonar-dashboard.yaml"
    destination = "/tmp/sonar-dashboard.yaml"
  }

  // gitlab
  provisioner "file" {
    destination = "/tmp/cert-manager-cloudflare-secret.yaml"
    content = templatefile(
      "${path.module}/gitlab/cert-manager-cloudflare-secret.yaml.tpl",
      {
        "api_key" : "${var.cloudflare_api_key}"
      }
    )
  }

  provisioner "file" {
    source      = "gitlab/issuer.yaml"
    destination = "/tmp/issuer.yaml"
  }

  # argocd
  provisioner "file" {
    source      = "argocd/repo-secret.yaml"
    destination = "/tmp/repo-secret.yaml"
  }

  provisioner "file" {
    source      = "argocd/applicationset.yaml"
    destination = "/tmp/applicationset.yaml"
  }

  provisioner "file" {
    source      = "argocd/servicemonitor.yaml"
    destination = "/tmp/argocd-servicemonitor.yaml"
  }

  provisioner "file" {
    source      = "argocd/dashboard.yaml"
    destination = "/tmp/argocd-dashboard.yaml"
  }

  provisioner "file" {
    destination = "/tmp/argocd-image-updater-config.yaml"
    content = templatefile(
      "${path.module}/argocd/argo-image-updater-config.yaml.tpl",
      {
        "domain" : "${var.prefix}.${var.domain}"
      }
    )
  }

  provisioner "file" {
    destination = "/tmp/argocd-vaules.yaml"
    content = templatefile(
      "${path.module}/argocd/values.yaml.tpl",
      {
        "domain" : "${var.prefix}.${var.domain}"
      }
    )
  }

  # harbor

  provisioner "file" {
    source      = "harbor/issuer.yaml"
    destination = "/tmp/harbor-issuer.yaml"
  }

  provisioner "file" {
    source      = "harbor/servicemonitor.yaml"
    destination = "/tmp/harbor-servicemonitor.yaml"
  }

  provisioner "file" {
    source      = "harbor/dashboard.yaml"
    destination = "/tmp/harbor-dashboard.yaml"
  }

  provisioner "file" {
    destination = "/tmp/harbor-values.yaml"
    content = templatefile(
      "${path.module}/harbor/values.yaml.tpl",
      {
        "domain" : "${var.prefix}.${var.domain}"
      }
    )
  }

  // cosign
  provisioner "file" {
    destination = "/tmp/cosign-key-password.yaml"
    content = templatefile(
      "${path.module}/cosign/cosign-key-password.yaml.tpl",
      {
        "cosign_password" : "${var.cosign_password}"
      }
    )
  }

  provisioner "file" {
    source      = "cosign/cosign-key-file-secret.yaml"
    destination = "/tmp/cosign-key-file-secret.yaml"
  }

  provisioner "remote-exec" {
    # script = "/tmp/init.sh"
    inline = [
      "chmod +x /tmp/init.sh",
      "sh /tmp/init.sh",
    ]
  }
}
