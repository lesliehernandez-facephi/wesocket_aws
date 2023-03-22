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

}


# declaración permite que la función de Lambda cree grupos
#  de registros, cree flujos de registros y transfiera eventos 
#  de registro a CloudWatch Logs
data "aws_iam_policy_document" "ws_lambda_policy" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    effect   = "Allow"
    resource = ["arn:aws:logs:*:*:*"]
  }

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
  statement {
    actions = [
      "execute-api:*",
    ]
    effect   = "Allow"
    resource = [
      "${aws_apigatewayv2_stage.ws_messenger_api_stage.execution_arn}/PING"
    ] 
  }

}

data  "aws_iam_policy_document" "ws_messeger_apigateway_policy" {
  statement {
    actions = [
      "lambda:InvokeFunction",
    ]
    effect   = "Allow"
    resource = [aws_lambda_function.ws_go_chat.arn]
  }
}

resource "aws_iam_policy" "ws_messenger_lambda_policy" {
  name   = "WsMessengerLambdaPolicy"
  path   = "/"
  policy = data.aws_iam_policy_document.ws_messenger_lambda_policy.json
}

resource "aws_iam_policy" "ws_messenger_api_gateway_policy" {
  name   = "WsMessengerAPIGatewayPolicy"
  path   = "/"
  policy = data.aws_iam_policy_document.ws_messenger_api_gateway_policy.json
}


resource "aws_iam_role" "ws_messenger_api_gateway_role" {
  name = "WsMessengerAPIGatewayRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      },
    ]
  })

  managed_policy_arns = [aws_iam_policy.ws_messenger_api_gateway_policy.arn]
}



# ###################################################
#                                                   #
# las politicas de la lambda                        #
#                                                   #
####################################################

resource "aws_iam_role" "chat_go" {
  name               = "chat_go"
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
    role              = aws_iam_role.chat_go.arn
    source_code_hash  = sha256(filebase64("main.zip"))
    memory_size       = 128
    timeout           = 10


    environment {
      variables = {
        "API_GATEWAY_ENDPOINT" = "https://${aws_apigatewayv2_api.websocket_go.id}.execute-api.eu-west-2.amazonaws.com/${aws_apigatewayv2_stage.ws_messenger_api_stage.id}"
        # "DYNAMODB_TABLE"       = aws_dynamodb_table.ws_messenger_table.id
      }
    }
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

resource "aws_apigatewayv2_api" "websocket_go" {
    name                       = "ws_messenger_api"
    description                = "Send data for the WS"
    protocol_type              = "WEBSOCKET"
    route_selection_expression = "$request.body.action"
}

# la aws_apigatewayv2_integration es para estar atento a los servicios que se solicita 
resource "aws_apigatewayv2_integration" "ws_messenger_api_integration" {
  api_id                    = aws_apigatewayv2_api.websocket_go.id
  integration_type          = "AWS_PROXY"
  integration_uri           = aws_lambda_function.ws_go_chat.invoke_arn
  # credentials_arn           = aws_iam_role.ws_messenger_api_gateway_role.arn
  content_handling_strategy = "CONVERT_TO_TEXT"
  passthrough_behavior      = "WHEN_NO_MATCH"
}

resource "aws_apigatewayv2_route" "ws_messenger_api_ping_route" {
  api_id    = aws_apigatewayv2_api.websocket_go.id
  route_key = "PING"
  target    = "integrations/${aws_apigatewayv2_integration.ws_messenger_api_integration.id}"
}

resource "aws_apigatewayv2_route_response" "ws_messenger_api_ping_route_response" {
  api_id             = aws_apigatewayv2_api.websocket_go.id
  route_id           = aws_apigatewayv2_route.ws_messenger_api_ping_route.id
  route_response_key = "$default"
}

resource "aws_apigatewayv2_stage" "ws_messenger_api_stage" {
  api_id      = aws_apigatewayv2_api.websocket_go.id
  name        = "developers"
  auto_deploy = true
}

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


# ahora vamos hacer una implementacion "real" 
# resource "aws_apigatewayv2_stage" "lambda" {
#   api_id      = aws_apigatewayv2_api.websocket_go.id
#   name        = "ws_primary"
#   auto_deploy = true
# }

# Allow the API Gateway to invoke Lambda function
resource "aws_lambda_permission" "ws_messenger_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ws_go_chat.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.websocket_go.execution_arn}/*/*"
}


