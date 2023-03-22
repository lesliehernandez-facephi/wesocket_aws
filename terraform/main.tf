# terraform {
# required_providers {
#     aws = {
#       source  = "hashicorp/aws"
#       version = "~> 4.16"
#     }
#   }
# # 
#   backend "s3" {
#     bucket = "local-dm-tfstate"
#     key    = "ws-chat/terraform.tfstate"
#     region = var.aws_region
#   }

#   required_version = ">= 1.3.6"
# }

provider aws {
  region = var.aws_region
  # profile = var.profile
}


# declaración permite que la función de Lambda cree grupos
#  de registros, cree flujos de registros y transfiera eventos 
#  de registro a CloudWatch Logs
# data "aws_iam_policy_document" "ws_lambda_policy" {
#   statement {
#     actions = [
#       "logs:CreateLogGroup",
#       "logs:CreateLogStream",
#       "logs:PutLogEvents"
#     ]
#     effect   = "Allow"
#     resource = ["arn:aws:logs:*:*:*"]
#   }

# permite que la función Lambda coloque elementos,
#  elimine elementos y escanee el contenido de una tabla de Amazon DynamoDB
  # statement {
  #   actions = [
  #     "dynamodb:PutItem",
  #     "dynamodb:DeleteItem",
  #     "dynamodb:Scan",
  #   ]
  #   effect   = "Allow"
  #   resource = [aws_dynamodb_table.ws_messenger_table.arn]
  # }

# declaración permite que la función Lambda ejecute API en API Gateway
#   statement {
#     actions = [
#       "execute-api:*",
#     ]
#     effect   = "Allow"
#     resource = [
#       "${aws_apigatewayv2_stage.ws_messenger_api_stage.execution_arn}/*/*/*"
#     ] 
#   }

# }


# data  "aws_iam_policy_document" "ws_messeger_apigateway_policy" {
#   statement {
#     actions = [
#       "lambda:InvokeFunction",
#     ]
#     effect   = "Allow"
#     resource = [aws_lambda_function.ws_lambda_messeger.arn]
#   }
# }


# ##############################################################
# Copilacion del codigo                                        #
# en esta parte pondremos que se copile el codigo               
# y se guarde en el zip, mediante terraform, sin necesidad de 
# que nosotros tengamos que estar haciendolo manualmente, 
# si no solo con el comando terraform apply se construye toda 
# la infraestructura del codgio como el del despliegue
# resource "null_resource" "compile" {
#     trigger = {
#         build_number = "${timestamp()}"
#     }

#     provider "local-exec" {
#         command = "GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -o ./main -ldflags '-w' ./main.go"
#     }
# }


# ###################################################
#                                                   #
# las politicas de la lambda                        #
#                                                   #
####################################################

resource "aws_iam_role" "examplego" {
  name               = "examplego"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": {
    "Action": "sts:AssumeRole",
    "Principal": {
      "Service": "lambda.amazonaws.com"
    },
    "Effect": "Allow"
  }
}
POLICY
}

# ##################################################
#                                                  #
# Se crea la funcion Lambda para                   #
####################################################
resource "aws_lambda_function" "ws_go_chat" {
    function_name     = "go_chat"
    runtime           = "go1.x"
    filename          = "main.zip"
    handler           = "main"
    role              = aws_iam_role.examplego.arn
    source_code_hash  = sha256(filebase64("main.zip"))
    memory_size       = 128
    timeout           = 10
}

# Creamos unos logs, con aws_cloudwatch_log_group

# resource "aws_cloudwatch_log_group" "ws_messenger_logs" {
#   name              = "/aws/lambda/${aws_lambda_function.ws_go_chat.function_name}"
#   retention_in_days = 7
# }


# ##################################################
#                                                  #
# Aqui creamos un APIGATEWAY para la lambda  
# loi que importa aqui en la palabra WEBSOCKET,
# dentro de aqui hay varios enrutamientos
# En esta expresion "$request.body.action", deciamos
# que en el bodyde la peticion hay una action,
# ahi es donde genera el enrutamiento
####################################################

# resource "aws_apigatewayv2_api" "websocket_go" {
#     name                       = "ws_messenger_api"
#     description                = "Send data for the WS"
#     protocol_type              = "WEBSOCKET"
#     route_selection_expression = "$request.body.action"
# }

# la aws_apigatewayv2_integration es para estar atento a los servicios que se solicita 
# resource "aws_apigatewayv2_integration" "lambda_main" {
#   api_id             = aws_apigatewayv2_api.websocket_go.id
#   integration_uri    = aws_lambda_function.ws_go_chat.invoke_arn
#   integration_type   = "AWS_PROXY"
#   integration_method = "POST"
# }

# aqui se reenvia las solicitudes especiales ($connect, $disconnect)
# para nuestra funcion lambda para poder administrar los estados de la lambda
# serian las subrutas que tiene la apigatewayv2
# resource "aws_apigatewayv2_route" "ws_connect" {
#   api_id    = aws_apigatewayv2_api.websocket_go.id
#   route_key = "$connect"
#   target    = "integrations/${aws_apigatewayv2_integration.lambda_main.id}"
# }

# resource "aws_apigatewayv2_route" "ws_disconnect" {
#   api_id    = aws_apigatewayv2_api.websocket_go.id
#   route_key = "$disconnect"
#   target    = "integrations/${aws_apigatewayv2_integration.lambda_main.id}"
# }

# resource "aws_apigatewayv2_route" "ws_default" {
#   api_id    = aws_apigatewayv2_api.websocket_go.id
#   route_key = "$default"
#   target    = "integrations/${aws_apigatewayv2_integration.lambda_main.id}"
# }


# # ahora vamos hacer una implementacion "real" 
# resource "aws_apigatewayv2_stage" "lambda" {
#   api_id      = aws_apigatewayv2_api.websocket_go.id
#   name        = "ws_primary"
#   auto_deploy = true
# }

# # Allow the API Gateway to invoke Lambda function
# resource "aws_lambda_permission" "ws_messenger_permission" {
#   statement_id  = "AllowExecutionFromAPIGateway"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.ws_go_chat.function_name
#   principal     = "apigateway.amazonaws.com"
#   source_arn    = "${aws_apigatewayv2_api.websocket_go.execution_arn}/*/*"
# }


