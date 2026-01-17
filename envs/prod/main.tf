module "eks" {
  source = "../../modules/eks"

  cluster_name       = "eks-prod"
  environment        = "prod"
  eks_version        = "1.29"
  private_subnet_ids = data.aws_subnets.private.ids
}

module "karpenter" {
  source = "../../modules/karpenter"

  cluster_name      = module.eks.cluster_name
  endpoint          = module.eks.endpoint
  ca                = module.eks.ca
  environment       = "prod"
  ssh_key_name      = "EKS"
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_issuer_url   = module.eks.oidc_issuer_url
  security_group_id = data.aws_security_group.office_ips.id
  subnet_ids        = data.aws_subnets.private.ids
  vpc_id            = data.aws_vpc.eks_vpc.id
}
