# Para generar el main en MAC
 GOOS=linux GOARCH=amd64 go build -o main main.go 

# Para generar el main en Windows, esto es muy importante para poder guardarlo en un zip y que se despligue en aws lambdas
 go.exe install github.com/aws/aws-lambda-go/cmd/build-lambda-zip@latest
 $env:GOOS = "linux"
 $env:GOARCH = "amd64"
 $env:CGO_ENABLED = "0"
 go build -o main main.go

# es opcional porque dentro de terraform estamos generando el .zip
 ~\Go\Bin\build-lambda-zip.exe -o main.zip main 

# Realizar una peticion de un websocket en un terminal 
 wscat -c "RUTA"

# Realizarlo por un terminal 
  { "action": "sendmessage", "payload":{"username":"leslie", "message": "Aqui cualquier mensaje"} }