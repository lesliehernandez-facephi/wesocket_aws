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
data "aws_iam_policy_document" "ws_lambda_policy_document" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    effect   = "Allow"
    resources = ["arn:aws:logs:*:*:*"]
  }

# permite que la función Lambda coloque elementos,
#  elimine elementos y escanee el contenido de una tabla de Amazon DynamoDB
  statement {
    actions = [
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
      "dynamodb:Scan",
    ]
    effect   = "Allow"
    resources = [aws_dynamodb_table.ws_table.arn]
  }

# declaración permite que la función Lambda ejecute API en API Gateway
  statement {
    actions = [
      "execute-api:*",
    ]
    effect   = "Allow"
    resource = [
      "${aws_apigatewayv2_stage.lambda_stage.execution_arn}/*/*/*"
    ] 
  }
}

resource "aws_iam_policy" "ws_lambda_policy" {
  name   = "WsMessengerLambdaPolicy"
  path   = "/"
  policy = data.aws_iam_policy_document.ws_lambda_policy_document.json
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
  managed_policy_arns = [aws_iam_policy.ws_lambda_policy.arn]
}

# ##################################################
#                                                  #
# Se crea la funcion Lambda para                   #
####################################################
# resource "null_resource" "function_binary" {
#   provisioner "local-exec" {
#     command = "GOOS=linux GOARCH=amd64 go build -o ../main ../main.go"
#   }
# }

data "archive_file" "zip" {    
    # depends_on = [null_resource.function_binary]
    type        = "zip"
    source_file = "../main"
    output_path = "../main.zip"
}


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

# # Allow the API Gateway to invoke Lambda function
resource "aws_lambda_permission" "ws_messenger_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ws_go_chat.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.websocket_go.execution_arn}/*/*"
}

resource "aws_dynamodb_table" "ws_table" {
  name           = "websocket-table"
  billing_mode   = "PROVISIONED"
  read_capacity  = 2
  write_capacity = 2
  hash_key       = "ConnectionID"

  attribute {
    name = "ConnectionID"
    type = "S"
  }

  ttl {
    attribute_name = "ExpirationTime"
    enabled        = true
  }
}