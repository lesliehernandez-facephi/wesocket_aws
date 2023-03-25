package main

import (
	"encoding/json"
	"os"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/awserr"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/apigatewaymanagementapi"
	"github.com/aws/aws-sdk-go/service/dynamodb"
	"github.com/aws/aws-sdk-go/service/dynamodb/dynamodbattribute"
	"go.uber.org/zap"
)

// Inicialización de logs
var Loggers, _ = zap.NewProduction()

// Estructura para almacenar IDs de conexión en DynamoDB
type Connection struct {
	ConnectionID string
}

// Estructuras para enviar mensajes
type Payload struct {
	Username string `json:"username"`
	Message  string `json:"message"`
}
type Body struct {
	Action  string  `json:"action"`
	Payload Payload `json:"payload"`
}

func handleRequest(request events.APIGatewayWebsocketProxyRequest) (events.APIGatewayProxyResponse, error) {
	var response events.APIGatewayProxyResponse

	switch route := request.RequestContext.RouteKey; route {
	case "$connect":
		Loggers.Info("$connect ", zap.String("body: ", request.Body))
		response = doConnect(request.RequestContext.ConnectionID)
	case "sendmessage":
		Loggers.Info("sendmessage", zap.String("body: ", request.Body))
		response = doSendMessage(request.Body)
	case "$disconnect":
		Loggers.Info("$disconnect", zap.String("body: ", request.Body))
		response = doDisconnect(request.RequestContext.ConnectionID, request.Body)
	default:
		Loggers.Error(route, zap.String("body: ", request.Body))
		response = events.APIGatewayProxyResponse{Body: "Invalid route: " + route, StatusCode: 400}
	}

	Loggers.Info("response", zap.String("body: ", response.Body))
	return response, nil
}

func doConnect(connectionID string) events.APIGatewayProxyResponse {
	label := "doConnect: "
	Loggers.Info(label + "connectionID: " + connectionID)

	newSession, err := session.NewSession()

	if err != nil {
		return events.APIGatewayProxyResponse{Body: "Failed establishing AWS session: " + err.Error(), StatusCode: 500}
	}

	dbSvc := dynamodb.New(newSession)

	av, err := dynamodbattribute.MarshalMap(&Connection{ConnectionID: connectionID})

	if err != nil {
		return events.APIGatewayProxyResponse{Body: "Failed marshalling DynamoDB item: " + err.Error(), StatusCode: 500}
	}

	tableName := os.Getenv("DYNAMODB_TABLE")
	Loggers.Info(label + "tableName: " + tableName)

	_, err = dbSvc.PutItem(&dynamodb.PutItemInput{Item: av, TableName: aws.String(tableName)})

	if err != nil {
		return events.APIGatewayProxyResponse{Body: "Failed putting DynamoDB item in table '" + tableName + "': " + err.Error(), StatusCode: 500}
	}

	return events.APIGatewayProxyResponse{Body: connectionID, StatusCode: 200}
}

func doSendMessage(body string) events.APIGatewayProxyResponse {
	label := "doSendMessage: "
	newSession, err := session.NewSession()

	if err != nil {
		return events.APIGatewayProxyResponse{Body: "Failed establishing AWS session: " + err.Error(), StatusCode: 500}
	}

	msg := Body{}

	err = json.Unmarshal([]byte(body), &msg)

	if err != nil {
		return events.APIGatewayProxyResponse{Body: "Failed unmarshalling body message: " + err.Error(), StatusCode: 500}
	}

	Loggers.Info(label + "Body: " + body)
	Loggers.Info(label + "Message.Action: " + msg.Action)

	endUrl := os.Getenv("API_GATEWAY_ENDPOINT")
	tableName := os.Getenv("DYNAMODB_TABLE")
	apiGw := apigatewaymanagementapi.New(newSession, aws.NewConfig().WithEndpoint(endUrl))
	dbSvc := dynamodb.New(newSession)

	result, err := dbSvc.Scan(&dynamodb.ScanInput{TableName: aws.String(tableName)})

	if err != nil {
		return events.APIGatewayProxyResponse{Body: "Failed scanning DynamoDB table '" + tableName + "': " + err.Error(), StatusCode: 500}
	}

	connectionIds := make([]Connection, *result.Count)
	err = dynamodbattribute.UnmarshalListOfMaps(result.Items, &connectionIds)

	if err != nil {
		return events.APIGatewayProxyResponse{Body: "Failed unmarshalling connection IDs: " + err.Error(), StatusCode: 500}
	}

	for _, c := range connectionIds {
		Loggers.Info(label + "Posting to connection ID: " + c.ConnectionID)

		payload, err := json.Marshal(msg.Payload)

		if err != nil {
			return events.APIGatewayProxyResponse{Body: "Failed marshalling payload: " + err.Error(), StatusCode: 500}
		}

		_, err = apiGw.PostToConnection(&apigatewaymanagementapi.PostToConnectionInput{ConnectionId: &c.ConnectionID, Data: payload})

		if err != nil {
			// El error puede ser que el usuario se ha desconectado, en ese caso habría que eliminarlo
			// En cualquier otro caso, detenerse y devolver error
			answerError, ok := err.(awserr.Error)

			if ok && answerError.Code() == apigatewaymanagementapi.ErrCodeGoneException {
				err = deleteConnection(c.ConnectionID)
				if err != nil {
					return events.APIGatewayProxyResponse{Body: "Error deleting connection ID '" + c.ConnectionID + "' in DynamoDB: " + err.Error(), StatusCode: 500}
				}
			} else {
				return events.APIGatewayProxyResponse{Body: "Error posting message to connection ID '" + c.ConnectionID + "'" + err.Error(), StatusCode: 500}
			}
		}
	}

	return events.APIGatewayProxyResponse{Body: "{}", StatusCode: 200}
}

func doDisconnect(connectionID string, body string) events.APIGatewayProxyResponse {
	err := deleteConnection(connectionID)

	if err != nil {
		return events.APIGatewayProxyResponse{Body: "Error deleting connection ID '" + connectionID + "' in DynamoDB: " + err.Error(), StatusCode: 500}
	}

	return events.APIGatewayProxyResponse{Body: body, StatusCode: 200}
}

func deleteConnection(connectionID string) error {
	Loggers.Info("deleteConnection: connection ID: " + connectionID)

	tableName := os.Getenv("DYNAMODB_TABLE")
	newSession, err := session.NewSession()

	if err != nil {
		return err
	}

	dbSvc := dynamodb.New(newSession)
	delIn := &dynamodb.DeleteItemInput{
		Key: map[string]*dynamodb.AttributeValue{
			"ConnectionID": {S: aws.String(connectionID)},
		},
		// ReturnValues: aws.String("ALL_OLD"),
		TableName: aws.String(tableName),
	}
	if _, err := dbSvc.DeleteItem(delIn); err != nil {
		return err
	}
	return nil
}

// Main
func main() {
	lambda.Start(handleRequest)
}
