terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.53.0"
    }

  }
  required_version = ">= 1.3.6"
}

provider aws {
  region = var.aws_region
}

# ###################################################
#                                                   #
# las politicas de la lambda                        #
#                                                   #
####################################################


# creacion de politicas de permisos de IAM, para los recursos usados en la app Chat
data "aws_iam_policy_document" "ws_lambda_policy_document" {
  # es para permitir registrar los logs
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    effect   = "Allow"
    resources = ["arn:aws:logs:*:*:*"]
  }

# permite que la función Lambda que use dynamoDB
  statement {
    actions = [
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
      "dynamodb:Scan",
    ]
    effect   = "Allow"
    resources = [aws_dynamodb_table.ws_table.arn]
  }

  statement {
    actions = [
      "execute-api:*",
    ]
    effect   = "Allow"
    resources = [
      "${aws_apigatewayv2_stage.lambda_stage.execution_arn}/*/*/*"
    ] 
  }
}

# creacion de los permisos de IAM
resource "aws_iam_policy" "ws_lambda_policy" {
  name   = "WsMessengerLambdaPolicy"
  path   = "/"
  policy = data.aws_iam_policy_document.ws_lambda_policy_document.json
}

# permite que apigateway invoque a la funcion lambda
data  "aws_iam_policy_document" "ws_messeger_apigateway_policy" {
  statement {
    actions = [
      "lambda:InvokeFunction",
    ]
    effect   = "Allow"
    resources = [aws_lambda_function.ws_go_chat.arn]
  }
}


# se administa los roles de la funcion lambda
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
  managed_policy_arns = [aws_iam_policy.ws_lambda_policy.arn]
}

# resource "null_resource" "function_binary" {
#   provisioner "local-exec" {
#     command = "GOOS=linux GOARCH=amd64 go build -o ../main ../main.go"
#   }
# }

# se genera el fichero zip del main
data "archive_file" "zip" {    
    # depends_on = [null_resource.function_binary]
    type        = "zip"
    source_file = "../main"
    output_path = "../main.zip"
}

# lambda funcion de nuestra aplicacion. 
resource "aws_lambda_function" "ws_go_chat" {
    function_name     = "go_chat"
    runtime           = "go1.x"
    filename          = "../main.zip"
    handler           = "main"
    role              = aws_iam_role.examplego.arn
    source_code_hash = "data.archive_file.zip.output_base64sha256"
    # source_code_hash  = sha256(filebase64("../main.zip"))
    environment {
      variables = {
        "API_GATEWAY_ENDPOINT" = "https://${aws_apigatewayv2_api.websocket_go.id}.execute-api.eu-west-2.amazonaws.com/${aws_apigatewayv2_stage.lambda_stage.id}"
        "DYNAMODB_TABLE"       = aws_dynamodb_table.ws_table.id
      }
    }
    memory_size       = 128
    timeout           = 10
}

# Creamos unos logs, con aws_cloudwatch_log_group
resource "aws_cloudwatch_log_group" "ws_messenger_logs" {
  name              = "/aws/lambda/${aws_lambda_function.ws_go_chat.function_name}"
  retention_in_days = 7
}

# es para dar permisos a la apigateway, para que invoque a la lambda funcion.
resource "aws_lambda_permission" "ws_messenger_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ws_go_chat.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.websocket_go.execution_arn}/*/*"
}

# aqui se crea la tabla en dynamoDB
resource "aws_dynamodb_table" "ws_table" {
  name           = "websocket-table"
  hash_key       = "ConnectionID"
  billing_mode   = "PROVISIONED"
  read_capacity  = 2
  write_capacity = 2

  attribute {
    name = "ConnectionID"
    type = "S"
  }

  ttl {
    attribute_name = "ExpirationTime"
    enabled        = true
  }
}