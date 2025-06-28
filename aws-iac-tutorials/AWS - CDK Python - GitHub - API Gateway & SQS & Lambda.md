## DOCS:
https://github.com/aws-samples/aws-cdk-examples/blob/main/python/api-sqs-lambda/README.md

## Source Obtaining

```
git clone https://github.com/aws-samples/aws-cdk-examples.git
cd aws-cdk-examples/python/api-sqs-lambda
```

In this pattern, the CDK code creates 
- an API Gateway API with a POST Method
- a SQS queue
- a Lambda function
Requests to the API are enqueued into the SQS queue, which triggers the Lambda function.


## Setup up your environment

Manually create a virtualenv.
```
python -m venv .env
```

Activate your virtualenv.
```
.env\Scripts\activate
```

Once the virtualenv is activated, you can install the required dependencies.
```
pip install -r requirements.txt
```

At this point you can now synthesize the CloudFormation template for this code.
```
cdk synth
```

Install & configure your aws command line tool if needed.
```
pip install awscli
```

```
aws configure
```

## Refine your codes

NOTES:
The runtime parameter of python3.7 is no longer supported for creating or updating AWS Lambda functions. We recommend you use a supported runtime while creating or updating functions.
## Deploy the stack

```
cdk synth
```

```
cdk deploy
```

## Validate

```
aws apigateway test-invoke-method --rest-api-id  **********  --resource-id ******  --http-method POST --body '{key1:value1}'
```

## Clean the resources

```
cdk destroy
```


