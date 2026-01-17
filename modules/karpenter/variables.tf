variable "cluster_name" {}
variable "endpoint" {}
variable "ca" {}
variable "environment" {}
variable "ssh_key_name" {}
variable "oidc_provider_arn" {}
variable "oidc_issuer_url" {}
variable "security_group_id" {}
variable "subnet_ids" {
  type = list(string)
}
variable "vpc_id" {}