module "vpc" {
  source = "./modules/vpc"

  vpc_cidr          = var.vpc_cidr
  access_ip         = var.access_ip
  public_sn_count   = var.public_sn_count
  public_cidrs      = var.public_cidrs
  instance_tenancy  = var.instance_tenancy
  tags              = var.tags
}

module "eks" {
  source = "./modules/eks"

  vpc_id            = module.vpc.vpc_id
  aws_public_subnet = module.vpc.public_subnets
}

resource "null_resource" "update_kubeconfig" {
  depends_on = [module.eks]

  triggers = {
    cluster_name = module.eks.cluster_name
  }

  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region us-west-2"
  }
}

resource "null_resource" "deploy_elk" {
  depends_on = [null_resource.update_kubeconfig]

  triggers = {
    elk_files_hash = sha256(join("", [
      for f in fileset("${path.module}/elk", "**") : filesha256("${path.module}/elk/${f}")
    ]))
  }

  provisioner "local-exec" {
    command = <<-EOT
      kubectl create namespace elk --dry-run=client -o yaml | kubectl apply -f -
      kubectl apply -f ${path.module}/elk/filebeat-service-account.yaml
      kubectl apply -f ${path.module}/elk/filebeat-cluster-role.yaml
      kubectl apply -f ${path.module}/elk/filebeat-cluster-role-binding.yaml
      kubectl apply -f ${path.module}/elk/logstash-configmap.yaml
      kubectl apply -f ${path.module}/elk/filebeat-configmap.yaml
      kubectl apply -f ${path.module}/elk/
    EOT
  }
}