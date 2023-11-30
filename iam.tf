################################################################################
## task execution role
################################################################################
data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "execution" {
  name               = "backstage-${var.environment}-execution"
  assume_role_policy = data.aws_iam_policy_document.assume.json

  tags = merge(var.tags, tomap({
    Name = "backstage-${var.environment}-execution"
  }))
}

resource "aws_iam_policy_attachment" "execution" {
  for_each = toset(var.execution_policy_attachment_arns)

  name       = "backstage-${var.environment}-execution"
  policy_arn = each.value
  roles      = [aws_iam_role.execution.name]
}

// TODO: fix below
data "aws_secretsmanager_secret" "backstage_secret" {
  name = var.secret_name
}

data "aws_secretsmanager_secret" "backstage_private_key" {
  name = var.private_key_secret_name
}

################################################################################
## secrets manager
################################################################################
resource "aws_iam_policy" "secrets_manager_read_policy" {
  name = "backstage-${var.environment}-secrets-manager-ro"

  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Resource = [
          data.aws_secretsmanager_secret.backstage_secret.arn,
          data.aws_secretsmanager_secret.backstage_private_key.arn
        ]
        Action = [
          "secretsmanager:GetSecretValue"
        ],
      }
    ]
  })

  tags = merge(var.tags, tomap({
    Name = "backstage-${var.environment}-secrets-manager-ro"
  }))
}

resource "aws_iam_role_policy_attachment" "secrets_manager_read" {
  role       = aws_iam_role.execution.name
  policy_arn = aws_iam_policy.secrets_manager_read_policy.arn
}
