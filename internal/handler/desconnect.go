package handler

import (
	"context"
	"log"
	"net/http"
	"os"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/feature/dynamodb/attributevalue"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/lesliehernandez-facephi/wesocket_aws/internal/helpers"
)

func Desconectado(ctx context.Context, event events.APIGatewayWebsocketProxyRequest) (events.APIGatewayProxyResponse, error) {

	log.Printf("desconectandoooo id: %s ", event.RequestContext.ConnectionID)

	svc, err := helpers.DataBaseDyanmodb(ctx)

	if err != nil {
		return events.APIGatewayProxyResponse{}, nil
	}

	key, err := attributevalue.MarshalMap(map[string]string{
		"ConnectionID": event.RequestContext.ConnectionID,
	})

	if err != nil {
		return events.APIGatewayProxyResponse{}, nil
	}

	input := &dynamodb.DeleteItemInput{
		TableName: aws.String(os.Getenv("DYNAMODB_TABLE")),
		Key:       key,
	}

	svc.DeleteItem(ctx, input)
	return events.APIGatewayProxyResponse{
		StatusCode: http.StatusOK,
	}, nil
}
