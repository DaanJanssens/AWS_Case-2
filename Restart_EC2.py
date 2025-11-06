import boto3 # type: ignore

def lambda_handler(event, context):
    ec2 = boto3.client('ec2', region_name='eu-central-1')

    response = ec2.describe_instances(
        Filters=[{'Name': 'instance-state-name', 'Values': ['running']}]
    )

    instance_ids = [
        i['InstanceId']
        for reservation in response.get('Reservations', [])
        for i in reservation.get('Instances', [])
    ]

    if instance_ids:
        print(f"Rebooting instances: {instance_ids}")
        ec2.reboot_instances(InstanceIds=instance_ids)
        message = f"Rebooted instences: {instance_ids}"
    else:
        message = f"No running instances found"

    print(message)

    return {"statusCode": 200, "body": message}