# Tag subnets for Karpenter discovery
resource "aws_ec2_tag" "karpenter_discovery" {
  for_each    = toset(var.private_subnet_ids)
  resource_id = each.value
  key         = "karpenter.sh/discovery/${var.cluster_name}"
  value       = var.cluster_name
}

# Also tag with generic discovery tag
resource "aws_ec2_tag" "karpenter_discovery_generic" {
  for_each    = toset(var.private_subnet_ids)
  resource_id = each.value
  key         = "karpenter.sh/discovery"
  value       = var.cluster_name
}
