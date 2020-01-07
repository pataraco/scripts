{
  "Comment": "A Hello World example demonstrating various state types of the Amazon States Language",
  "StartAt": "Pass",
  "States": {
    "Pass": {
      "Comment": "A Pass state passes its input to its output, without performing work. Pass states are useful when constructing and debugging state machines.",
      "Type": "Pass",
      "Next": "Calculate?"
    },
    "Calculate?": {
      "Comment": "A Choice state adds branching logic to a state machine. Choice rules can implement 16 different comparison operators, and can be combined using And, Or, and Not",
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.Calculate",
          "BooleanEquals": true,
          "Next": "Yes"
        },
        {
          "Variable": "$.Calculate",
          "BooleanEquals": false,
          "Next": "No"
        }
      ],
      "Default": "Yes"
    },
    "Yes": {
      "Type": "Pass",
      "Next": "Wait 1 sec"
    },
    "No": {
      "Type": "Fail",
      "Cause": "Not Hello World"
    },
    "Wait 1 sec": {
      "Comment": "A Wait state delays the state machine from continuing for a specified time.",
      "Type": "Wait",
      "Seconds": 1,
      "Next": "Parallel State"
    },
    "Parallel State": {
      "Comment": "A Parallel state can be used to create parallel branches of execution in your state machine.",
      "Type": "Parallel",
      "Next": "Hello World",
      "Branches": [
        {
          "StartAt": "8",
          "States": {
            "8": {
              "Comment": "Return square of 8",
              "Type": "Pass",
              "Result": {"number": 8},
              "Next": "calc8squared"
            },
            "calc8squared": {
              "Comment": "Return square of number",
              "Type": "Task",
              "Resource": "arn:aws:lambda:us-west-2:088872216852:function:SquareCalc",
              "TimeoutSeconds": 3,
              "End": true
            }
          }
        },
        {
          "StartAt": "64",
          "States": {
            "64": {
              "Comment": "Return square of 64",
              "Type": "Pass",
              "Result": {"number": 64},
              "Next": "calc64squared"
            },
            "calc64squared": {
              "Comment": "Return square of number",
              "Type": "Task",
              "TimeoutSeconds": 3,
              "Resource": "arn:aws:lambda:us-west-2:088872216852:function:SquareCalc",
              "End": true
            }
          }
        }
      ]
    },
    "Hello World": {
      "Type": "Pass",
      "End": true
    }
  }
}
