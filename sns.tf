resource "aws_sns_topic" "techno-sns" {
    name = "techno-sns-payakumbuh-akbar"
}

resource "aws_sns_topic_subscription" "techno-admin" {
    topic_arn = aws_sns_topic.techno-sns.arn
    protocol = "email"
    endpoint = "muhammadzafirulakbar88@gmail.com"
}