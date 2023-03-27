# Hola👋 
# Bienvendio al chat con Websocket con Lambdas. 🚀
# Escrito en golang y desplegado con terraform en AWS Lambdas 👨‍💻

  *  Hay que crear un ejecutable del main.go (funciona solo para LINUX o MAC)
    GOOS=linux GOARCH=amd64 go build -o main main.go **

  * Para generar el ejecutable main en Windows
    ```
    $env:GOOS = "linux"
    $env:GOARCH = "amd64"
    $env:CGO_ENABLED = "0"
    go build -o main main.go

    ```
  * Es opcional porque dentro de terraform estamos generando el .zip
    ```
    go.exe install github.com/aws/aws-lambda-go/cmd/build-lambda-zip@latest

    ~\Go\Bin\build-lambda-zip.exe -o main.zip main 
    ```

 * Realizar una peticion de un websocket en un terminal 
   Previamente descargado, en 
    ```
    npm install -g wscat 
    wscat -c "RUTA"
    ```
  * Realizarlo por un terminal 
   ``` { "action": "sendmessage", "payload":{"username":"leslie", "message": "Aqui cualquier mensaje"} } ```

# Finalmente para desplegarlo en la PC tienes que seguir estos pasos
  1º terraform init
  2º terraform apply
  Dentro de aws, en el apartdado de apigateway, damos click en el nombre de la apigateway
  una vez dentro nos metemos en el apartado etapas, nos metemos dentro y copiamos la URL pero que empeiza por ws://....
