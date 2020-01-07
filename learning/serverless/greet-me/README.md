# Simple "Greet Me" lambda function

```bash
$ npm init
$ zip -r greet-me.zip *
$ aws s3 cp greet-me.zip s3://S3_BUCKET/functions/latest/
$ aws lambda update-function-code --function-name greetMe --s3-bucket S3_BUCKET --s3-key functions/latest/greet-me.zip --publish
```
