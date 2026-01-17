data "aws_vpc" "eks_vpc" {
  tags = {
    Name = "EKS-vpc"
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.eks_vpc.id]
  }

  filter {
    name   = "tag:Name"
    values = ["EKS-private1", "EKS-private2"]
  }
}

# Lookup security group by name and VPC (security groups are VPC-scoped)
data "aws_security_group" "office_ips" {
  filter {
    name   = "group-name"
    values = ["EKS-sg"]
  }
  
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.eks_vpc.id]
  }
  
  # If lookup fails, uncomment to use security group ID directly:
  # id = "sg-051868f3b487275eb"
}

data "aws_subnet" "private" {
  for_each = toset(data.aws_subnets.private.ids)
  id       = each.value
}
