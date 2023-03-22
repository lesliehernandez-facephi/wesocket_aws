package main

import (
	"context"
	"encoding/json"
	"log"

	"github.com/lesliehernandez-facephi/wesocket_aws/internal/handler"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
)

func Handler(ctx context.Context, event events.APIGatewayWebsocketProxyRequest) (events.APIGatewayProxyResponse, error) {
	content, err := json.Marshal(event)

	if err != nil {
		return events.APIGatewayProxyResponse{}, err
	}

	log.Printf("new event. content: %s", string(content))

	switch event.RequestContext.RouteKey {
	case "$connect":
		return handler.Conectado(ctx, event)
	case "$disconnect":
		return handler.Desconectado(ctx, event)
	case "$PING":
		return handler.Ping(ctx, event)
	case "$MESSAGE":
		return handler.Messages(ctx, event)
	default:
		return events.APIGatewayProxyResponse{Body: "no handler", StatusCode: 200}, nil

	}

}

func main() {
	lambda.Start(Handler)
}
