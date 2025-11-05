resource "aws_sns_topic" "ec2_down" {
  name = "EC2InstanceDownTopic"
}

resource "aws_sns_topic_subscription" "email_sub" {
  topic_arn = aws_sns_topic.ec2_down.arn
  protocol = "email"
  endpoint = "555086@student.fontys.nl"
}