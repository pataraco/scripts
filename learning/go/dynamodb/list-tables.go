package main

import (
	"fmt"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/awserr"
	"github.com/aws/aws-sdk-go/aws/endpoints"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/dynamodb"
)

func main() {
	// svc := session.Must(session.NewSession(&aws.DynomoDb{
	//     Region: aws.String(endpoints.UsWest2RegionID),
	// }))
	// svc := dynamodb.New(session.New())
	svc := dynamodb.New(session.New(), &aws.Config{
	    Region: aws.String(endpoints.UsWest2RegionID),
	})
	input := &dynamodb.ListTablesInput{}

	result, err := svc.ListTables(input)
	if err != nil {
		if aerr, ok := err.(awserr.Error); ok {
			switch aerr.Code() {
			case dynamodb.ErrCodeInternalServerError:
				fmt.Println(dynamodb.ErrCodeInternalServerError, aerr.Error())
			default:
				fmt.Println(aerr.Error())
			}
		} else {
			// Print the error, cast err to awserr.Error to get the Code and
			// Message from an error.
			fmt.Println(err.Error())
		}
		return
	}

	fmt.Println(result)
}
