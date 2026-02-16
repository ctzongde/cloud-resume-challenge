# go to the file named retrieveVisitorCountPython.py and import the lambda_handler function
from retrieveVisitorCountPython import lambda_handler
# import json module to convert JSON text to a Python object
import json

# test function to check if the lambda_handler returns a valid count
def test_lambda_returns_count():
    # call the lambda_handler function with empty event and context
    response = lambda_handler({}, None)

    # checks if response status code is 200
    assert response["statusCode"] == 200

    # parse the body of the response as JSON
    body = json.loads(response ["body"])
    
    # checks if the body contains a "count" key and that its value is an integer
    assert "count" in body
    # check if the count is an integer
    assert isinstance(body["count"], int)
    # check if the count is non-negative
    assert body["count"] >= 0