package handler

import (
	"context"
	"encoding/json"
	"log"
	"net/http"
	_ "time"

	_ "github.com/lesliehernandez-facephi/wesocket_aws/internal/helpers"
	"github.com/lesliehernandez-facephi/wesocket_aws/internal/model"

	"github.com/aws/aws-lambda-go/events"
	_ "github.com/aws/aws-sdk-go-v2/aws"
	_ "github.com/aws/aws-sdk-go-v2/feature/dynamodb/attributevalue"
	_ "github.com/aws/aws-sdk-go-v2/service/dynamodb"
)

func Ping(ctx context.Context, event events.APIGatewayWebsocketProxyRequest) (events.APIGatewayProxyResponse, error) {
	log.Printf("ping a mensajes")

	const pongActions = "PONG"
	//svc, erres := helpers.DataBaseDyanmodb(ctx)
	/*if erres != nil {
		return events.APIGatewayProxyResponse{}, erres
	}

	item, err := attributevalue.MarshalMap(model.Connection{
		ConnectionID:   event.RequestContext.ConnectionID,
		ExpirationTime: int(time.Now().Add(5 * time.Minute).Unix()),
	})
	if err != nil {
		return events.APIGatewayProxyResponse{}, err
	}

	input := &dynamodb.PutItemInput{
		TableName: aws.String("ws_messeger_table"),
		Item:      item,
	}
	/*if _, erres = svc.PutItem(ctx, input); erres != nil {
		return events.APIGatewayProxyResponse{}, erres
	}*/

	response := model.Response[model.PongResponsePayload]{
		Action:   pongActions,
		Response: model.PongResponsePayload{},
	}

	content, er := json.Marshal(response)
	if er != nil {
		return events.APIGatewayProxyResponse{}, er
	}
	log.Printf("pong response is %s ", string(content))

	return events.APIGatewayProxyResponse{
		Body:       string(content),
		StatusCode: http.StatusOK,
	}, nil
}
