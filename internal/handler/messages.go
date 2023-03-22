package handler

import (
	"context"
	"encoding/json"
	"log"
	"net/http"
	"os"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/feature/dynamodb/attributevalue"
	"github.com/aws/aws-sdk-go-v2/feature/dynamodb/expression"
	"github.com/aws/aws-sdk-go-v2/service/apigatewaymanagementapi"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/lesliehernandez-facephi/wesocket_aws/internal/helpers"
	"github.com/lesliehernandez-facephi/wesocket_aws/internal/model"
)

func Messages(ctx context.Context, event events.APIGatewayWebsocketProxyRequest) (events.APIGatewayProxyResponse, error) {
	log.Printf("Nuevo messages!!!!")

	const messagesAction = "MESSAGE"

	svc, err := helpers.DataBaseDyanmodb(ctx)
	if err != nil {
		return events.APIGatewayProxyResponse{}, err
	}

	var request model.Request[model.MessageRequestPayload]
	if err := json.Unmarshal([]byte(event.Body), &request); err != nil {
		return events.APIGatewayProxyResponse{}, nil
	}

	filt := expression.Name("ConnectionID").NotEqual(expression.Value(event.RequestContext.ConnectionID))
	proyec := expression.NamesList(expression.Name("ConnectionID"))
	expre, err := expression.NewBuilder().WithFilter(filt).WithProjection(proyec).Build()
	if err != nil {
		return events.APIGatewayProxyResponse{}, err
	}

	input := &dynamodb.ScanInput{
		TableName:                 aws.String(os.Getenv("DYNAMODB_TABLE")),
		ExpressionAttributeNames:  expre.Names(),
		ExpressionAttributeValues: expre.Values(),
		FilterExpression:          expre.Filter(),
		ProjectionExpression:      expre.Projection(),
		Limit:                     aws.Int32(100),
	}

	output, err := svc.Scan(ctx, input)
	if err != nil {
		return events.APIGatewayProxyResponse{}, err
	}

	log.Printf("Se contro %d activa la conexion ", output.Count)

	api, err := helpers.APIgateway(ctx)
	if err != nil {
		return events.APIGatewayProxyResponse{}, err
	}

	for _, item := range output.Items {
		var connections model.Connection

		if err := attributevalue.UnmarshalMap(item, &connections); err != nil {
			return events.APIGatewayProxyResponse{}, err
		}

		newMessages := model.Response[model.MessageRequestPayload]{
			Action: messagesAction,
			Response: model.MessageRequestPayload{
				Message: request.Payload.Message,
			},
		}

		data, err := json.Marshal(newMessages)
		if err != nil {
			return events.APIGatewayProxyResponse{}, err
		}

		input := &apigatewaymanagementapi.PostToConnectionInput{
			ConnectionId: aws.String(connections.ConnectionID),
			Data:         data,
		}

		if _, err = api.PostToConnection(ctx, input); err != nil {
			return events.APIGatewayProxyResponse{}, err
		}
	}

	return events.APIGatewayProxyResponse{
		StatusCode: http.StatusOK,
	}, nil
}
