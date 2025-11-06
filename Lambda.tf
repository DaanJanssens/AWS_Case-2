resource "aws_iam_role" "lambda_restart_rol" {
  name = "ec2_restart_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role" "lambda_role" {
  name = "ec2_down_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Principal = {
        Service = "lambda.amazonaws.com"
      },
      Effect = "Allow",
    }]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "lambda_ec2_restart_policy"
  role = aws_iam_role.lambda_restart_rol.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["ec2:DescribeInstances", "ec2:RebootInstances"]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "sns_access" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSNSFullAccess"
}

data "archive_file" "lambda_restart_zip" {
  type = "zip"
  source_file = "${path.module}/Restart_EC2.py"
  output_path = "${path.module}/Restart_EC2.zip"
}

data "archive_file" "lambda_alert_zip" {
  type        = "zip"
  source_file = "${path.module}/Send_Alert.py"
  output_path = "${path.module}/Send_Alert.zip"
}

resource "aws_lambda_function" "restart_ec2" {
  function_name = "RestartEC2Instances"
  runtime = "python3.12"
  handler = "Restart_EC2.lambda_handler"
  filename = data.archive_file.lambda_restart_zip.output_path
  role = aws_iam_role.lambda_restart_rol.arn
  timeout = 120
}

resource "aws_lambda_function" "send_alert" {
  function_name = "SendEC2DownAlert"
  runtime       = "python3.12"
  handler       = "Send_Alert.lambda_handler"
  filename      = data.archive_file.lambda_alert_zip.output_path
  role          = aws_iam_role.lambda_role.arn

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.ec2_down.arn
    }
  }
}

resource "aws_cloudwatch_event_rule" "daily_1am" {
  name = "Daily1AMRestart"
  schedule_expression = "cron(0 1 * * ? *)"
  description = "Triggers restart of EC2 instances every night"
}

resource "aws_cloudwatch_event_rule" "ec2_state_change" {
  name        = "EC2InstanceDownRule"
  description = "Triggers when a EC2 instance stops or terminates"

  event_pattern = jsonencode({
    source        = ["aws.ec2"],
    "detail-type" = ["EC2 Instance State-change Notification"],
    detail = {
      state = ["stopped", "terminated"]
    }
  })
}

resource "aws_cloudwatch_event_target" "restart_target" {
  rule = aws_cloudwatch_event_rule.daily_1am.name
  target_id = "lambda"
  arn = aws_lambda_function.restart_ec2.arn
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.ec2_state_change.name
  target_id = "SendEC2DownAlert"
  arn       = aws_lambda_function.send_alert.arn
}

resource "aws_lambda_permission" "allow_restart" {
  statement_id = "AllowExecutionFromCloudWatch"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.restart_ec2.function_name
  principal = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.daily_1am.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.send_alert.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ec2_state_change.arn
}