#/bin/bash
terraform state rm 'module.k3s'
terraform state rm 'module.k3s-2'
terraform state rm 'module.k3s-3'
terraform destroy -auto-approve