# Create Karpenter namespace
resource "kubernetes_namespace_v1" "karpenter" {
  metadata {
    name = "karpenter"
  }
}

# EC2NodeClass for Karpenter
resource "kubernetes_manifest" "karpenter_node_class" {
  manifest = {
    apiVersion = "karpenter.k8s.aws/v1beta1"
    kind       = "EC2NodeClass"
    metadata = {
      name = "default"
    }
    spec = {
      amiFamily = "AL2"
      subnetSelectorTerms = [
        {
          tags = {
            "karpenter.sh/discovery" = var.cluster_name
          }
        }
      ]
      securityGroupSelectorTerms = [
        {
          id = var.security_group_id
        }
      ]
      instanceStorePolicy = "NVME"
      tags = {
        Environment = var.environment
        ManagedBy   = "Karpenter"
      }
      launchTemplate = {
        metadataOptions = {
          httpEndpoint            = "enabled"
          httpProtocolIpv6        = "disabled"
          httpPutResponseHopLimit = 2
          httpTokens              = "required"
        }
      }
      # SSH key configuration for future access
      # Note: KeyName is configured via launchTemplate in newer Karpenter versions
      userData = <<-EOT
        #!/bin/bash
        /etc/eks/bootstrap.sh ${var.cluster_name}
      EOT
      instanceProfile = "karpenter-node-${var.environment}"
      blockDeviceMappings = [
        {
          deviceName = "/dev/xvda"
          ebs = {
            volumeSize           = "20Gi"
            volumeType           = "gp3"
            iops                 = 3000
            deleteOnTermination  = true
          }
        }
      ]
    }
  }

  depends_on = [
    helm_release.karpenter,
    kubernetes_namespace_v1.karpenter
  ]
}

# NodePool for Karpenter
resource "kubernetes_manifest" "karpenter_node_pool" {
  manifest = {
    apiVersion = "karpenter.sh/v1beta1"
    kind       = "NodePool"
    metadata = {
      name = "default"
    }
    spec = {
      template = {
        metadata = {
          labels = {
            Environment = var.environment
          }
        }
        spec = {
          nodeClassRef = {
            name = "default"
          }
          requirements = [
            {
              key      = "kubernetes.io/arch"
              operator = "In"
              values   = ["amd64"]
            },
            {
              key      = "kubernetes.io/os"
              operator = "In"
              values   = ["linux"]
            },
            {
              key      = "karpenter.sh/capacity-type"
              operator = "In"
              values   = ["spot", "on-demand"]
            },
            {
              key      = "node.kubernetes.io/instance-type"
              operator = "In"
              values   = ["t3.medium", "t3.large", "t3.xlarge", "m5.large", "m5.xlarge"]
            }
          ]
        }
      }
      limits = {
        cpu = "1000"
      }
      disruption = {
        consolidationPolicy = "WhenEmpty"
        consolidateAfter    = "30s"
      }
    }
  }

  depends_on = [
    helm_release.karpenter,
    kubernetes_namespace.karpenter,
    kubernetes_manifest.karpenter_node_class
  ]
}
