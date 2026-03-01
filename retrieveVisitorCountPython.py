import json
import boto3

# iniitialize DynamoDB resource
dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table("visitor-counter")

# Function runs when Lambda is called
def lambda_handler(event, context):
    # increases the visitor count by 1
    response = table.update_item(
        # identify the item to update
        Key={"id": "resume"},
        # increment the count attribute by 1 or set it to 1 if it does not exist
        UpdateExpression="SET #count = if_not_exists(#count, :start) + :incr",
        ExpressionAttributeNames={"#count": "count"},
        ExpressionAttributeValues={":start": 0, ":incr": 1},
        ReturnValues="UPDATED_NEW"
    )

    new_count = int(response["Attributes"]["count"])

    return {
        'statusCode': 200,
        'body': json.dumps({
            "count": new_count
        })
    }