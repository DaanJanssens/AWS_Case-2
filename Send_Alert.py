import boto3 # type: ignore

sns = boto3.client('sns')

def lambda_handler(event, context):
    detail = event.get('detail', {})
    instance_id = detail.get('instance-id', 'Unknown')
    state = detail.get('state', 'Unknown')

    message = f"EC2 Instance {instance_id} is now {state}"
    subject = f"Alert: EC2 instance {instance_id} is {state}"

    topic_arn = "REPLACE_ME"

    if state in ['stopped', 'terminated']:
        sns.publish(
            TopicArn=topic_arn,
            Subject=subject,
            Message=message
        )
    return {'status': 'done', 'state': state}