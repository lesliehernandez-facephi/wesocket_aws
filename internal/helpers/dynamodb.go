package helpers

import (
	"context"
	"log"
	"os"

	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
)

// aqui se crea una base de datos donde se guardan los mensajes de los clientes
// cada vez q se haga un deployment se de nuevo una BBDD

func DataBaseDyanmodb(cxt context.Context) (*dynamodb.Client, error) {

	aws, err := config.LoadDefaultConfig(cxt, config.WithRegion(os.Getenv("AWS_REGION")))
	log.Printf("New instance Dynamo storage [%s]")

	if err != nil {
		return nil, err
	}
	return dynamodb.NewFromConfig(aws), nil
}
