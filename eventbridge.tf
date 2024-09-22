resource "aws_cloudwatch_event_rule" "codecommit_push_master" {
  name        = "ai-agent-repo-push-to-master"
  description = "triggered when new push is added to branch master in the codecommit repository"

  event_pattern = jsonencode({
    source      = ["aws.codecommit"]
    detail-type = ["CodeCommit Repository State Change"]
    resources   = [var.repository_arn]
    detail = {
      event         = ["referenceCreated", "referenceUpdated"]
      referenceType = ["branch"]
      referenceName = ["master"]
    }
  })
}

resource "aws_cloudwatch_event_target" "codepipeline" {
  rule      = aws_cloudwatch_event_rule.codecommit_push_master.name
  target_id = "trigger-codepipeline"
  arn       = aws_codepipeline.pipeline.arn

  role_arn = aws_iam_role.trigger_codepipeline.arn
}

resource "aws_iam_role" "trigger_codepipeline" {
  name = "EventBridgeTriggerAiAgentCodepipeline"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "events.amazonaws.com"
        }
      },
    ]
  })

  managed_policy_arns = [aws_iam_policy.trigger_codepipeline.arn]
}

resource "aws_iam_policy" "trigger_codepipeline" {
  name        = "AiAgentCodePipelinePolicy"
  path        = "/"
  description = "Policy for the codepipeline"

  policy = data.aws_iam_policy_document.trigger_codepipeline.json
}

data "aws_iam_policy_document" "trigger_codepipeline" {
  statement {
    actions = [
      "codepipeline:StartPipelineExecution"
    ]
    resources = [aws_codepipeline.pipeline.arn]
    effect    = "Allow"
  }
}
