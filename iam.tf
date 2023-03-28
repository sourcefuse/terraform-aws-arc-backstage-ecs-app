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
  name_prefix        = "backstage-${var.environment}-execution-"
  assume_role_policy = data.aws_iam_policy_document.assume.json

  tags = merge(var.tags, tomap({
    NamePrefix = "backstage-${var.environment}-execution-"
  }))
}

resource "aws_iam_policy_attachment" "execution" {
  for_each = toset(var.execution_policy_attachment_arns)

  name       = "backstage-${var.environment}-execution"
  policy_arn = each.value
  roles      = [aws_iam_role.execution.name]
}

data "aws_secretsmanager_secret" "backstage_secret" {
  name = var.secret_name
}

################################################################################
## secrets manager
################################################################################
resource "aws_iam_policy" "secrets_manager_read_policy" {
  name_prefix = "backstage-${var.environment}-secrets-manager-ro-"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Resource = [data.aws_secretsmanager_secret.backstage_secret.arn]
        Action = [
          "secretsmanager:GetSecretValue"
        ],
      }
    ]
  })

  tags = merge(var.tags, tomap({
    NamePrefix = "backstage-${var.environment}-secrets-manager-ro-"
  }))
}

resource "aws_iam_policy_attachment" "secrets_manager_read" {
  name       = "backstage-${var.environment}-secrets-manager-ro"
  roles      = [aws_iam_role.execution.name]
  policy_arn = aws_iam_policy.secrets_manager_read_policy.arn
}
