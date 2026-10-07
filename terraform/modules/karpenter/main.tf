resource "aws_iam_role" "karpenter_node" {
  name = "karpenter-node-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "karpenter_node_policies" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ])
  policy_arn = each.value
  role       = aws_iam_role.karpenter_node.name
}

resource "aws_iam_role" "karpenter_controller" {
  name = "microservice-karpenter-controller"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = ["sts:AssumeRole", "sts:TagSession"]
      Effect    = "Allow"
      Principal = { Service = "pods.eks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "karpenter_controller" {
  name = "karpenter-policy"
  role = aws_iam_role.karpenter_controller.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "ec2:CreateFleet",
        "ec2:CreateLaunchTemplate",
        "ec2:CreateTags",
        "ec2:DescribeAvailabilityZones",
        "ec2:DescribeImages",
        "ec2:DescribeInstances",
        "ec2:DescribeInstanceTypeOfferings",
        "ec2:DescribeInstanceTypes",
        "ec2:DescribeLaunchTemplates",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeSpotPriceHistory",
        "ec2:DescribeSubnets",
        "ec2:RunInstances",
        "ec2:TerminateInstances",
        "pricing:GetProducts",
        "ssm:GetParameter",
        "iam:GetInstanceProfile",
        "iam:PassRole"
      ],
      Effect   = "Allow",
      Resource = "*"
    }]
  })

}

resource "aws_eks_pod_identity_association" "karpenter" {
  cluster_name    = var.cluster_name
  namespace       = "kube-system"
  service_account = "karpenter"
  role_arn        = aws_iam_role.karpenter_controller.arn
}

resource "helm_release" "karpenter" {
  namespace        = "kube-system"
  name             = "karpenter"
  repository       = "oci://public.ecr.aws/karpenter"
  chart            = "karpenter"
  version          = "1.14.1"
  create_namespace = true
  set = [
    {
      name  = "settings.clusterName"
      value = var.cluster_name
    },
    {
       name  = "settings.clusterEndpoint"
       value = var.cluster_endpoint
    },
  ]
  depends_on = [aws_eks_pod_identity_association.karpenter]
}

resource "aws_iam_instance_profile" "karpenter_node" {
  name = "microservice-karpenter-node-profile"
  role = aws_iam_role.karpenter_node.name
  depends_on = [
    aws_iam_role_policy_attachment.karpenter_node_policies
  ]
}

resource "aws_eks_access_entry" "karpenter_node" {
  cluster_name  = var.cluster_name
  principal_arn = aws_iam_role.karpenter_node.arn
  type          = "EC2_LINUX"
}

/*
resource "kubernetes_manifest" "karpenter_node_class" {
  manifest = {
    apiVersion = "karpenter.k8s.aws/v1"
    kind       = "EC2NodeClass"
    metadata = {
      name = "default"
    }
    spec = {
      amiFamily = "AL2023"
      amiSelectorTerms = [
        { alias = "al2023@v20260930" }
      ]
      instanceProfile = aws_iam_instance_profile.karpenter_node.name
      subnetSelectorTerms = [
        { tags = { "kubernetes.io/role/internal-elb" = "1" } }
      ]
      securityGroupSelectorTerms = [
        { tags = { "aws:eks:cluster-name" = var.cluster_name } }
      ]

    }
  }
  depends_on = [
    helm_release.karpenter,
    aws_eks_access_entry.karpenter_node,
    aws_iam_role_policy.karpenter_controller
  ]
}

resource "kubernetes_manifest" "karpenter_node_pool" {
  manifest = {
    apiVersion = "karpenter.sh/v1"
    kind       = "NodePool"
    metadata = {
      name = "default"
    }
    spec = {
      template = {
        spec = {
          nodeClassRef = {
            group = "karpenter.k8s.aws"
            kind  = "EC2NodeClass"
            name  = "default"
          }
          requirements = [
            {
              key      = "kubernetes.io/arch"
              operator = "In"
              values   = ["amd64"]
            },
            {
              key      = "karpenter.k8s.aws/instance-family"
              operator = "In"
              values   = ["t3", "m7i"]
            }
          ]
        }
      }
      limits = {
        cpu    = "100"
        memory = "100Gi"
      }
    }
  }
  depends_on = [kubernetes_manifest.karpenter_node_class]
}
*/