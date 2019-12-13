{
  "Comment": "Triggered by uploads to S3 by lambda event notif. Then resizes jpg files into thumbnails.",
  "StartAt": "GetFileType",
  "States": {
    "GetFileType": {
      "Type": "Task",
      "Resource": "arn:aws:lambda:us-west-2:123456789012:function:GetS3FileType",
      "TimeoutSeconds": 300,
      "HeartbeatSeconds": 60,
      "ResultPath": "$.results.fileType",
      "Catch": [
        {
          "ErrorEquals": ["States.ALL"],
          "Next": "CaughtError"
        }
      ],
      "Next": "CheckFileType"
    },
    "CheckFileType": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.results.fileType",
          "StringEquals": "jpg",
          "Next": "Process"          
        }
      ],
      "Default": "Delete"
    },
    "Process": {
      "Type": "Parallel",
      "ResultPath": "$.results.images",
      "Branches": [
          {
            "StartAt": "CopyToDest",
            "States": {
              "CopyToDest": {
                "Type": "Task",
                "Resource": "arn:aws:lambda:us-west-2:123456789012:function:CopyS3UploadsToBeProcessed",
                "TimeoutSeconds": 300,
                "HeartbeatSeconds": 60,
                "Retry": [
                  {
                    "ErrorEquals": ["States.TaskFailed", "States.Timeout"],
                    "IntervalSeconds": 5,
                    "MaxAttempts": 2,
                    "BackoffRate": 2.0
                  },
                  {
                    "ErrorEquals": ["States.ALL"],
                    "IntervalSeconds": 2,
                    "MaxAttempts": 2,
                    "BackoffRate": 2.0
                  }
                ],
                "Catch": [
                  {
                    "ErrorEquals": ["States.ALL"],
                    "Next": "CopyError"
                  }
                ],
                "ResultPath": "$.image.copyToDest",
                "OutputPath": "$.image",
                "End": true
              },
              "CopyError": {
                "Type": "Fail",
                "Error": "S3 copy error",
                "Cause": "Lamba Execution Error"
              }
            }
          },
          {
            "StartAt": "Resize",
            "States": {
              "Resize": {
                "Type": "Task",
                "Resource": "arn:aws:lambda:us-west-2:123456789012:function:ResizeImage",
                "TimeoutSeconds": 300,
                "HeartbeatSeconds": 60,
                "Retry": [
                  {
                    "ErrorEquals": ["States.TaskFailed", "States.Timeout"],
                    "IntervalSeconds": 5,
                    "MaxAttempts": 2,
                    "BackoffRate": 2.0
                  },
                  {
                    "ErrorEquals": ["States.ALL"],
                    "IntervalSeconds": 2,
                    "MaxAttempts": 2,
                    "BackoffRate": 2.0
                  }
                ],
                "Catch": [
                  {
                    "ErrorEquals": ["States.ALL"],
                    "Next": "ResizeError"
                  }
                ],
                "ResultPath": "$.image.resize",
                "OutputPath": "$.image",
                "End": true
              },
              "ResizeError": {
                "Type": "Fail",
                "Error": "Image resize error",
                "Cause": "Lamba Execution Error"
              }
            }
          }
      ],
      "Next": "WriteToDDB"
    },
    "WriteToDDB": {
      "Type": "Task",
      "Resource": "arn:aws:lambda:us-west-2:123456789012:function:WriteToDynamoDB",
      "ResultPath": "$.results.writeStatus",
      "TimeoutSeconds": 300,
      "HeartbeatSeconds": 60,
      "Catch": [
        {
          "ErrorEquals": ["States.ALL"],
          "Next": "CaughtError"
        }
      ],
      "Next": "Delete"
    },
    "Delete": {
      "Type": "Task",
      "Resource": "arn:aws:lambda:us-west-2:123456789012:function:DeleteS3File",
      "TimeoutSeconds": 300,
      "HeartbeatSeconds": 60,
      "Catch": [
        {
          "ErrorEquals": ["States.ALL"],
          "Next": "CaughtError"
        }
      ],
      "End": true
    },
    "CaughtError": {
      "Type": "Fail",
      "Error": "CatchAllError",
      "Cause": "Lambda Execution Error"
    }
  }
}
