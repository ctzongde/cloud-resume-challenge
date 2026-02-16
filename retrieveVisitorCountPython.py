import json
import boto3

# iniitialize DynamoDB resource
dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table("VisitorCounter")

# Function runs when Lambda is called
def lambda_handler(event, context):
    # increases the visitor count by 1
    response = table.update_item(
        # identify the item to update
        Key={"id": "resume"},
        # increment the count attribute by 1
        UpdateExpression="SET #count = #count + :incr",
        ExpressionAttributeNames={"#count": "count"},
        ExpressionAttributeValues={":incr": 1},
        ReturnValues="UPDATED_NEW"
    )

    new_count = int(response["Attributes"]["count"])

    return {
        'statusCode': 200,
        'body': json.dumps({
            "count": new_count
        })
    }