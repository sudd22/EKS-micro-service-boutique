resource "aws_iam_role" "ebs_csi" {
  name = "microservice-eks-ebs-csi-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = ["sts:AssumeRole", "sts:TagSession"]
      Principal = { Service = "pods.eks.amazonaws.com" }
      Effect    = "Allow"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi.name
}

resource "aws_eks_pod_identity_association" "ebs_csi" {
  cluster_name    = var.cluster_name
  service_account = "ebs-csi-controller-sa"
  namespace       = "kube-system"
  role_arn        = aws_iam_role.ebs_csi.arn
}

resource "aws_eks_addon" "ebs_csi" {
  cluster_name = var.cluster_name
  addon_name   = "aws-ebs-csi-driver"
  depends_on   = [aws_eks_pod_identity_association.ebs_csi]
}

