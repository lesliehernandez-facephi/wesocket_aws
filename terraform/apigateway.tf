# ##################################################
#                                                  #
# Aqui creamos un APIGATEWAY para la lambda  
# loi que importa aqui en la palabra WEBSOCKET,
# dentro de aqui hay varios enrutamientos
# En esta expresion "$request.body.action", deciamos
# que en el bodyde la peticion hay una action,
# ahi es donde genera el enrutamiento
####################################################

# la aws_apigatewayv2_integration es para estar atento a los servicios que se solicita 
resource "aws_apigatewayv2_integration" "lambda_main" {
  api_id             = aws_apigatewayv2_api.websocket_go.id
  integration_uri    = aws_lambda_function.ws_go_chat.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
  content_handling_strategy = "CONVERT_TO_TEXT"
  passthrough_behavior      = "WHEN_NO_MATCH"
}


##############################
# # ahora vamos hacer una implementacion "real" 
resource "aws_apigatewayv2_stage" "lambda_stage" {
  api_id      = aws_apigatewayv2_api.websocket_go.id
  name        = "ws_primary"
  auto_deploy = true
}

resource "aws_apigatewayv2_api" "websocket_go" {
    name                       = "ws_messenger_api"
    description                = "Send data for the WS"
    protocol_type              = "WEBSOCKET"
    route_selection_expression = "$request.body.action"
}

# aqui se reenvia las solicitudes especiales ($connect, $disconnect)
# para nuestra funcion lambda para poder administrar los estados de la lambda
# serian las subrutas que tiene la apigatewayv2
resource "aws_apigatewayv2_route" "ws_connect" {
  api_id    = aws_apigatewayv2_api.websocket_go.id
  route_key = "$connect"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_main.id}"
}

resource "aws_apigatewayv2_route" "ws_disconnect" {
  api_id    = aws_apigatewayv2_api.websocket_go.id
  route_key = "$disconnect"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_main.id}"
}

resource "aws_apigatewayv2_route" "ws_default" {
  api_id    = aws_apigatewayv2_api.websocket_go.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_main.id}"
}

# resource "aws_apigatewayv2_route" "ws_ping_route" {
#   api_id    = aws_apigatewayv2_api.websocket_go.id
#   route_key = "PING"
#   target    = "integrations/${aws_apigatewayv2_integration.lambda_main.id}"
# }
################################
resource "aws_apigatewayv2_route" "ws_message_route" {
  api_id    = aws_apigatewayv2_api.websocket_go.id
  route_key = "sendmessage"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_main.id}"
}

resource "aws_apigatewayv2_integration_response" "ws_messenger_api_integration_response" {
  api_id                   = aws_apigatewayv2_api.websocket_go.id
  integration_id           = aws_apigatewayv2_integration.lambda_main.id
  integration_response_key = "/200/"
}

resource "aws_apigatewayv2_route_response" "ws_connect_route_response" {
  api_id             = aws_apigatewayv2_api.websocket_go.id
  route_id           = aws_apigatewayv2_route.ws_connect.id
  route_response_key = "$default"
}

resource "aws_apigatewayv2_route_response" "ws_disconnect_route_response" {
  api_id             = aws_apigatewayv2_api.websocket_go.id
  route_id           = aws_apigatewayv2_route.ws_disconnect.id
  route_response_key = "$default"
}

# resource "aws_apigatewayv2_route_response" "ws_ping_route_response" {
#   api_id             = aws_apigatewayv2_api.websocket_go.id
#   route_id           = aws_apigatewayv2_route.ws_ping_route.id
#   route_response_key = "$default"
# }

resource "aws_apigatewayv2_route_response" "ws_message_route_response" {
  api_id             = aws_apigatewayv2_api.websocket_go.id
  route_id           = aws_apigatewayv2_route.ws_message_route.id
  route_response_key = "$default"
}

resource "aws_apigatewayv2_route_response" "ws_default_route_response" {
  api_id             = aws_apigatewayv2_api.websocket_go.id
  route_id           = aws_apigatewayv2_route.ws_default.id
  route_response_key = "$default"
}