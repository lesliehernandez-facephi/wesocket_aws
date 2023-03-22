package handler

import (
	"context"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/feature/dynamodb/attributevalue"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/lesliehernandez-facephi/wesocket_aws/internal/helpers"
	"github.com/lesliehernandez-facephi/wesocket_aws/internal/model"
)

func Conectado(ctx context.Context, event events.APIGatewayWebsocketProxyRequest) (events.APIGatewayProxyResponse, error) {
	log.Printf("nueva conexion..  id: %s ", event.RequestContext.ConnectionID)

	svc, err := helpers.DataBaseDyanmodb(ctx)
	if err != nil {
		return events.APIGatewayProxyResponse{}, nil
	}

	item, err := attributevalue.MarshalMap(model.Connection{
		ConnectionID:   event.RequestContext.ConnectionID,
		ExpirationTime: int(time.Now().Add(5 * time.Minute).Unix()),
	})

	if err != nil {
		return events.APIGatewayProxyResponse{}, err
	}

	input := &dynamodb.PutItemInput{
		TableName: aws.String(os.Getenv("DYNAMODB_TABLE")),
		Item:      item,
	}

	svc.PutItem(ctx, input)
	return events.APIGatewayProxyResponse{
		StatusCode: http.StatusOK,
	}, nil
}
