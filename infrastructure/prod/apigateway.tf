###################
# API Gateway
###################

resource "aws_api_gateway_rest_api" "DoS_REST" {
    name = "DoS_REST"
    endpoint_configuration {
        types = ["REGIONAL"]
    }
}

/**************************
//
//SEARCH ENDPOINTS
//
**************************/


resource "aws_api_gateway_resource" "search" {
    parent_id   = aws_api_gateway_rest_api.DoS_REST.root_resource_id
    path_part   = "search"
    rest_api_id = aws_api_gateway_rest_api.DoS_REST.id
}

resource "aws_api_gateway_method" "search_POST" {
    authorization = "NONE"
    http_method   = "POST"
    resource_id   = aws_api_gateway_resource.search.id
    rest_api_id   = aws_api_gateway_rest_api.DoS_REST.id
    api_key_required = true
}

resource "aws_api_gateway_integration" "search_POST_integration" {
    rest_api_id = aws_api_gateway_rest_api.DoS_REST.id
    resource_id = aws_api_gateway_resource.search.id
    credentials = "${aws_iam_role.APIGatewaytoDoSSearchWorkflow.arn}"

    request_templates = {
        "application/json" = <<EOF
{
"input": "{\"search_query\":$util.escapeJavaScript($input.json('$.search_query')),\"api_key\":\"$context.identity.apiKey\"}",
"stateMachineArn": "${module.search_step_function.state_machine_arn}"
} 
        EOF
    }

    http_method             = "POST"
    integration_http_method = "POST"
    type                    = "AWS"
    passthrough_behavior    = "NEVER"
    uri                     = "arn:aws:apigateway:${var.aws_region}:states:action/StartSyncExecution"

}

resource "aws_api_gateway_method_response" "search_response" {
    rest_api_id = aws_api_gateway_rest_api.DoS_REST.id
    resource_id = aws_api_gateway_resource.search.id
    http_method = aws_api_gateway_method.search_POST.http_method
    status_code = "200"
}

resource "aws_api_gateway_integration_response" "search_integration_response" {
    rest_api_id = aws_api_gateway_rest_api.DoS_REST.id
    resource_id = aws_api_gateway_resource.search.id
    http_method = aws_api_gateway_method.search_POST.http_method
    status_code = aws_api_gateway_method_response.search_response.status_code
    response_templates = {
        "application/json" = <<EOF
#set ($parsedPayload = $util.parseJson($input.json('$.output')))
$parsedPayload
        EOF
    }
    depends_on = [aws_api_gateway_method_response.search_response]

}

/**************************
//
//SEARCH PROFILE ENDPOINTS
//
**************************/


resource "aws_api_gateway_resource" "searchprofiles" {
    parent_id   = aws_api_gateway_rest_api.DoS_REST.root_resource_id
    path_part   = "searchprofiles"
    rest_api_id = aws_api_gateway_rest_api.DoS_REST.id
}

resource "aws_api_gateway_method" "searchprofiles_POST" {
    authorization = "COGNITO_USER_POOLS"
    authorizer_id = aws_api_gateway_authorizer.DoS_Users.id
    http_method   = "POST"
    resource_id   = aws_api_gateway_resource.searchprofiles.id
    rest_api_id   = aws_api_gateway_rest_api.DoS_REST.id
}

resource "aws_api_gateway_method" "searchprofiles_GET" {
    authorization = "COGNITO_USER_POOLS"
    authorizer_id = aws_api_gateway_authorizer.DoS_Users.id
    http_method   = "GET"
    resource_id   = aws_api_gateway_resource.searchprofiles.id
    rest_api_id   = aws_api_gateway_rest_api.DoS_REST.id
}

resource "aws_api_gateway_method" "searchprofiles_DELETE" {
    authorization = "COGNITO_USER_POOLS"
    authorizer_id = aws_api_gateway_authorizer.DoS_Users.id
    http_method   = "DELETE"
    resource_id   = aws_api_gateway_resource.searchprofiles.id
    rest_api_id   = aws_api_gateway_rest_api.DoS_REST.id
}

resource "aws_api_gateway_integration" "searchprofiles_GET_integration" {
    rest_api_id             = aws_api_gateway_rest_api.DoS_REST.id
    resource_id             = aws_api_gateway_resource.searchprofiles.id
    http_method             = aws_api_gateway_method.searchprofiles_GET.http_method
    integration_http_method = "GET"
    type                    = "AWS_PROXY"
    uri                     = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${module.search-profile-manager-lambda.lambda_function_arn}/invocations"
}

resource "aws_api_gateway_integration" "searchprofiles_POST_integration" {
    rest_api_id             = aws_api_gateway_rest_api.DoS_REST.id
    resource_id             = aws_api_gateway_resource.searchprofiles.id
    http_method             = aws_api_gateway_method.searchprofiles_POST.http_method
    integration_http_method = "POST"
    type                    = "AWS_PROXY"
    uri                     = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${module.search-profile-manager-lambda.lambda_function_arn}/invocations"
}

resource "aws_api_gateway_integration" "searchprofiles_DELETE_integration" {
    rest_api_id             = aws_api_gateway_rest_api.DoS_REST.id
    resource_id             = aws_api_gateway_resource.searchprofiles.id
    http_method             = aws_api_gateway_method.searchprofiles_DELETE.http_method
    integration_http_method = "DELETE"
    type                    = "AWS_PROXY"
    uri                     = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${module.search-profile-manager-lambda.lambda_function_arn}/invocations"
}

/**************************
//
//SEARCH PROFILE / CONSUMER ENDPOINTS
//
**************************/

resource "aws_api_gateway_resource" "consumers" {
    parent_id   = aws_api_gateway_resource.searchprofiles.id
    path_part   = "consumers"
    rest_api_id = aws_api_gateway_rest_api.DoS_REST.id
}

resource "aws_api_gateway_method" "consumers_POST" {
    authorization = "COGNITO_USER_POOLS"
    authorizer_id = aws_api_gateway_authorizer.DoS_Users.id
    http_method   = "POST"
    resource_id   = aws_api_gateway_resource.consumers.id
    rest_api_id   = aws_api_gateway_rest_api.DoS_REST.id
}

resource "aws_api_gateway_method" "consumers_GET" {
    authorization = "COGNITO_USER_POOLS"
    authorizer_id = aws_api_gateway_authorizer.DoS_Users.id
    http_method   = "GET"
    resource_id   = aws_api_gateway_resource.consumers.id
    rest_api_id   = aws_api_gateway_rest_api.DoS_REST.id
}

resource "aws_api_gateway_method" "consumers_DELETE" {
    authorization = "COGNITO_USER_POOLS"
    authorizer_id = aws_api_gateway_authorizer.DoS_Users.id
    http_method   = "DELETE"
    resource_id   = aws_api_gateway_resource.consumers.id
    rest_api_id   = aws_api_gateway_rest_api.DoS_REST.id
}

resource "aws_api_gateway_integration" "consumers_GET_integration" {
    rest_api_id             = aws_api_gateway_rest_api.DoS_REST.id
    resource_id             = aws_api_gateway_resource.consumers.id
    http_method             = aws_api_gateway_method.consumers_GET.http_method
    integration_http_method = "GET"
    type                    = "AWS_PROXY"
    uri                     = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${module.search-profile-manager-lambda.lambda_function_arn}/invocations"
}

resource "aws_api_gateway_integration" "consumers_POST_integration" {
    rest_api_id             = aws_api_gateway_rest_api.DoS_REST.id
    resource_id             = aws_api_gateway_resource.consumers.id
    http_method             = aws_api_gateway_method.consumers_POST.http_method
    integration_http_method = "POST"
    type                    = "AWS_PROXY"
    uri                     = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${module.search-profile-manager-lambda.lambda_function_arn}/invocations"
}

resource "aws_api_gateway_integration" "consumers_DELETE_integration" {
    rest_api_id             = aws_api_gateway_rest_api.DoS_REST.id
    resource_id             = aws_api_gateway_resource.consumers.id
    http_method             = aws_api_gateway_method.consumers_DELETE.http_method
    integration_http_method = "DELETE"
    type                    = "AWS_PROXY"
    uri                     = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${module.search-profile-manager-lambda.lambda_function_arn}/invocations"
}

/**************************
//
//SERVICES ENDPOINTS
//
**************************/

resource "aws_api_gateway_resource" "services" {
    parent_id   = aws_api_gateway_rest_api.DoS_REST.root_resource_id
    path_part   = "services"
    rest_api_id = aws_api_gateway_rest_api.DoS_REST.id
}

resource "aws_api_gateway_method" "services_POST" {
    authorization = "COGNITO_USER_POOLS"
    authorizer_id = aws_api_gateway_authorizer.DoS_Users.id
    http_method   = "POST"
    resource_id   = aws_api_gateway_resource.services.id
    rest_api_id   = aws_api_gateway_rest_api.DoS_REST.id

    depends_on = [
        aws_api_gateway_resource.services
    ]
}

resource "aws_api_gateway_method" "services_PUT" {
    authorization = "COGNITO_USER_POOLS"
    authorizer_id = aws_api_gateway_authorizer.DoS_Users.id
    http_method   = "PUT"
    resource_id   = aws_api_gateway_resource.services.id
    rest_api_id   = aws_api_gateway_rest_api.DoS_REST.id

    depends_on = [
        aws_api_gateway_resource.services
    ]
}

resource "aws_api_gateway_method" "services_GET" {
    authorization = "COGNITO_USER_POOLS"
    authorizer_id = aws_api_gateway_authorizer.DoS_Users.id
    http_method   = "GET"
    resource_id   = aws_api_gateway_resource.services.id
    rest_api_id   = aws_api_gateway_rest_api.DoS_REST.id

    depends_on = [
        aws_api_gateway_resource.services
    ]
}

resource "aws_api_gateway_method" "services_DELETE" {
    authorization = "COGNITO_USER_POOLS"
    authorizer_id = aws_api_gateway_authorizer.DoS_Users.id
    http_method   = "DELETE"
    resource_id   = aws_api_gateway_resource.services.id
    rest_api_id   = aws_api_gateway_rest_api.DoS_REST.id

    depends_on = [
        aws_api_gateway_resource.services
    ]
}


resource "aws_api_gateway_integration" "services_GET_integration" {
    rest_api_id             = aws_api_gateway_rest_api.DoS_REST.id
    resource_id             = aws_api_gateway_resource.services.id
    http_method             = aws_api_gateway_method.services_GET.http_method
    integration_http_method = "POST"
    type                    = "AWS_PROXY"
    uri                     = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${module.directory-data-manager-lambda.lambda_function_arn}/invocations"

    depends_on = [
        aws_api_gateway_resource.services,
        aws_api_gateway_method.services_GET
    ]
}

resource "aws_api_gateway_integration" "services_POST_integration" {
    rest_api_id             = aws_api_gateway_rest_api.DoS_REST.id
    resource_id             = aws_api_gateway_resource.services.id
    http_method             = aws_api_gateway_method.services_POST.http_method
    integration_http_method = "POST"
    type                    = "AWS_PROXY"
    uri                     = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${module.directory-data-manager-lambda.lambda_function_arn}/invocations"

    depends_on = [
        aws_api_gateway_resource.services,
        aws_api_gateway_method.services_POST
    ]
}

resource "aws_api_gateway_integration" "services_PUT_integration" {
    rest_api_id             = aws_api_gateway_rest_api.DoS_REST.id
    resource_id             = aws_api_gateway_resource.services.id
    http_method             = aws_api_gateway_method.services_PUT.http_method
    integration_http_method = "POST"
    type                    = "AWS_PROXY"
    uri                     = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${module.directory-data-manager-lambda.lambda_function_arn}/invocations"

    depends_on = [
        aws_api_gateway_resource.services,
        aws_api_gateway_method.services_PUT
    ]
}

resource "aws_api_gateway_integration" "services_DELETE_integration" {
    rest_api_id             = aws_api_gateway_rest_api.DoS_REST.id
    resource_id             = aws_api_gateway_resource.services.id
    http_method             = aws_api_gateway_method.services_DELETE.http_method
    integration_http_method = "POST"
    type                    = "AWS_PROXY"
    uri                     = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${module.directory-data-manager-lambda.lambda_function_arn}/invocations"

    depends_on = [
        aws_api_gateway_resource.services,
        aws_api_gateway_method.services_DELETE
    ]
}


module "enable_cors_on_services" {
  source = "squidfunk/api-gateway-enable-cors/aws"
  version = "0.3.3"

  api_id          = aws_api_gateway_rest_api.DoS_REST.id
  api_resource_id = aws_api_gateway_resource.services.id

  depends_on = [
        aws_api_gateway_resource.services,
        aws_api_gateway_rest_api.DoS_REST
    ]
}

/**************************
//
//CAPACITY GRID ENDPOINTS
//
**************************/


resource "aws_api_gateway_resource" "capacitygrids" {
    parent_id   = aws_api_gateway_rest_api.DoS_REST.root_resource_id
    path_part   = "capacitygrids"
    rest_api_id = aws_api_gateway_rest_api.DoS_REST.id
}

resource "aws_api_gateway_method" "capacitygrids_POST" {
    authorization = "COGNITO_USER_POOLS"
    authorizer_id = aws_api_gateway_authorizer.DoS_Users.id
    http_method   = "POST"
    resource_id   = aws_api_gateway_resource.capacitygrids.id
    rest_api_id   = aws_api_gateway_rest_api.DoS_REST.id

    depends_on = [
        aws_api_gateway_resource.capacitygrids
    ]
}

resource "aws_api_gateway_method" "capacitygrids_PUT" {
    authorization = "COGNITO_USER_POOLS"
    authorizer_id = aws_api_gateway_authorizer.DoS_Users.id
    http_method   = "PUT"
    resource_id   = aws_api_gateway_resource.capacitygrids.id
    rest_api_id   = aws_api_gateway_rest_api.DoS_REST.id

    depends_on = [
        aws_api_gateway_resource.capacitygrids
    ]
}

resource "aws_api_gateway_method" "capacitygrids_GET" {
    authorization = "COGNITO_USER_POOLS"
    authorizer_id = aws_api_gateway_authorizer.DoS_Users.id
    http_method   = "GET"
    resource_id   = aws_api_gateway_resource.capacitygrids.id
    rest_api_id   = aws_api_gateway_rest_api.DoS_REST.id

    depends_on = [
        aws_api_gateway_resource.capacitygrids
    ]
}

resource "aws_api_gateway_method" "capacitygrids_DELETE" {
    authorization = "COGNITO_USER_POOLS"
    authorizer_id = aws_api_gateway_authorizer.DoS_Users.id
    http_method   = "DELETE"
    resource_id   = aws_api_gateway_resource.capacitygrids.id
    rest_api_id   = aws_api_gateway_rest_api.DoS_REST.id

    depends_on = [
        aws_api_gateway_resource.capacitygrids
    ]
}


resource "aws_api_gateway_integration" "capacitygrids_GET_integration" {
    rest_api_id             = aws_api_gateway_rest_api.DoS_REST.id
    resource_id             = aws_api_gateway_resource.capacitygrids.id
    http_method             = aws_api_gateway_method.capacitygrids_GET.http_method
    integration_http_method = "POST"
    type                    = "AWS_PROXY"
    uri                     = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${module.capacity-grids-manager-lambda.lambda_function_arn}/invocations"

    depends_on = [
        aws_api_gateway_resource.capacitygrids,
        aws_api_gateway_method.capacitygrids_GET
    ]
}

resource "aws_api_gateway_integration" "capacitygrids_POST_integration" {
    rest_api_id             = aws_api_gateway_rest_api.DoS_REST.id
    resource_id             = aws_api_gateway_resource.capacitygrids.id
    http_method             = aws_api_gateway_method.capacitygrids_POST.http_method
    integration_http_method = "POST"
    type                    = "AWS_PROXY"
    uri                     = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${module.capacity-grids-manager-lambda.lambda_function_arn}/invocations"

    depends_on = [
        aws_api_gateway_resource.capacitygrids,
        aws_api_gateway_method.capacitygrids_POST
    ]
}

resource "aws_api_gateway_integration" "capacitygrids_PUT_integration" {
    rest_api_id             = aws_api_gateway_rest_api.DoS_REST.id
    resource_id             = aws_api_gateway_resource.capacitygrids.id
    http_method             = aws_api_gateway_method.capacitygrids_PUT.http_method
    integration_http_method = "POST"
    type                    = "AWS_PROXY"
    uri                     = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${module.capacity-grids-manager-lambda.lambda_function_arn}/invocations"

    depends_on = [
        aws_api_gateway_resource.capacitygrids,
        aws_api_gateway_method.capacitygrids_PUT
    ]
}

resource "aws_api_gateway_integration" "capacitygrids_DELETE_integration" {
    rest_api_id             = aws_api_gateway_rest_api.DoS_REST.id
    resource_id             = aws_api_gateway_resource.capacitygrids.id
    http_method             = aws_api_gateway_method.capacitygrids_DELETE.http_method
    integration_http_method = "POST"
    type                    = "AWS_PROXY"
    uri                     = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${module.capacity-grids-manager-lambda.lambda_function_arn}/invocations"

    depends_on = [
        aws_api_gateway_resource.capacitygrids,
        aws_api_gateway_method.capacitygrids_DELETE
    ]
}


module "enable_cors_on_capacitygrids" {
  source = "squidfunk/api-gateway-enable-cors/aws"
  version = "0.3.3"

  api_id          = aws_api_gateway_rest_api.DoS_REST.id
  api_resource_id = aws_api_gateway_resource.capacitygrids.id

  depends_on = [
        aws_api_gateway_resource.capacitygrids,
        aws_api_gateway_rest_api.DoS_REST
    ]
}


/**************************
//
//CAPACITY DATA ENDPOINTS
//
**************************/


resource "aws_api_gateway_resource" "capacitydata" {
    parent_id   = aws_api_gateway_rest_api.DoS_REST.root_resource_id
    path_part   = "capacitydata"
    rest_api_id = aws_api_gateway_rest_api.DoS_REST.id
}

resource "aws_api_gateway_method" "capacitydata_POST" {
    authorization = "COGNITO_USER_POOLS"
    authorizer_id = aws_api_gateway_authorizer.DoS_Users.id
    http_method   = "POST"
    resource_id   = aws_api_gateway_resource.capacitydata.id
    rest_api_id   = aws_api_gateway_rest_api.DoS_REST.id

    depends_on = [
        aws_api_gateway_resource.capacitydata
    ]
}

resource "aws_api_gateway_method" "capacitydata_PUT" {
    authorization = "COGNITO_USER_POOLS"
    authorizer_id = aws_api_gateway_authorizer.DoS_Users.id
    http_method   = "PUT"
    resource_id   = aws_api_gateway_resource.capacitydata.id
    rest_api_id   = aws_api_gateway_rest_api.DoS_REST.id

    depends_on = [
        aws_api_gateway_resource.capacitydata
    ]
}

resource "aws_api_gateway_method" "capacitydata_GET" {
    authorization = "COGNITO_USER_POOLS"
    authorizer_id = aws_api_gateway_authorizer.DoS_Users.id
    http_method   = "GET"
    resource_id   = aws_api_gateway_resource.capacitydata.id
    rest_api_id   = aws_api_gateway_rest_api.DoS_REST.id

    depends_on = [
        aws_api_gateway_resource.capacitydata
    ]
}

resource "aws_api_gateway_method" "capacitydata_DELETE" {
    authorization = "COGNITO_USER_POOLS"
    authorizer_id = aws_api_gateway_authorizer.DoS_Users.id
    http_method   = "DELETE"
    resource_id   = aws_api_gateway_resource.capacitydata.id
    rest_api_id   = aws_api_gateway_rest_api.DoS_REST.id

    depends_on = [
        aws_api_gateway_resource.capacitydata
    ]
}


resource "aws_api_gateway_integration" "capacitydata_GET_integration" {
    rest_api_id             = aws_api_gateway_rest_api.DoS_REST.id
    resource_id             = aws_api_gateway_resource.capacitydata.id
    http_method             = aws_api_gateway_method.capacitydata_GET.http_method
    integration_http_method = "POST"
    type                    = "AWS_PROXY"
    uri                     = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${module.capacity-data-manager-lambda.lambda_function_arn}/invocations"

    depends_on = [
        aws_api_gateway_resource.capacitydata,
        aws_api_gateway_method.capacitydata_GET
    ]
}

resource "aws_api_gateway_integration" "capacitydata_POST_integration" {
    rest_api_id             = aws_api_gateway_rest_api.DoS_REST.id
    resource_id             = aws_api_gateway_resource.capacitydata.id
    http_method             = aws_api_gateway_method.capacitydata_POST.http_method
    integration_http_method = "POST"
    type                    = "AWS_PROXY"
    uri                     = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${module.capacity-data-manager-lambda.lambda_function_arn}/invocations"

    depends_on = [
        aws_api_gateway_resource.capacitydata,
        aws_api_gateway_method.capacitydata_POST
    ]
}

resource "aws_api_gateway_integration" "capacitydata_PUT_integration" {
    rest_api_id             = aws_api_gateway_rest_api.DoS_REST.id
    resource_id             = aws_api_gateway_resource.capacitydata.id
    http_method             = aws_api_gateway_method.capacitydata_PUT.http_method
    integration_http_method = "POST"
    type                    = "AWS_PROXY"
    uri                     = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${module.capacity-data-manager-lambda.lambda_function_arn}/invocations"

    depends_on = [
        aws_api_gateway_resource.capacitydata,
        aws_api_gateway_method.capacitydata_PUT
    ]
}

resource "aws_api_gateway_integration" "capacitydata_DELETE_integration" {
    rest_api_id             = aws_api_gateway_rest_api.DoS_REST.id
    resource_id             = aws_api_gateway_resource.capacitydata.id
    http_method             = aws_api_gateway_method.capacitydata_DELETE.http_method
    integration_http_method = "POST"
    type                    = "AWS_PROXY"
    uri                     = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${module.capacity-data-manager-lambda.lambda_function_arn}/invocations"

    depends_on = [
        aws_api_gateway_resource.capacitydata,
        aws_api_gateway_method.capacitydata_DELETE
    ]
}


module "enable_cors_on_capacitydata" {
  source = "squidfunk/api-gateway-enable-cors/aws"
  version = "0.3.3"

  api_id          = aws_api_gateway_rest_api.DoS_REST.id
  api_resource_id = aws_api_gateway_resource.capacitydata.id

  depends_on = [
        aws_api_gateway_resource.capacitydata,
        aws_api_gateway_rest_api.DoS_REST
    ]
}


resource "aws_api_gateway_deployment" "main" {
    rest_api_id = aws_api_gateway_rest_api.DoS_REST.id

    triggers = {
        redeployment = sha1(jsonencode([
        aws_api_gateway_rest_api.DoS_REST
        ]))
    }

    lifecycle {
        create_before_destroy = true
    }

    depends_on = [
        aws_api_gateway_rest_api.DoS_REST,
        aws_api_gateway_method.services_GET
    ]
}

resource "aws_api_gateway_stage" "main" {
    deployment_id = aws_api_gateway_deployment.main.id
    rest_api_id   = aws_api_gateway_rest_api.DoS_REST.id
    stage_name    = "main"
}


resource "aws_api_gateway_authorizer" "DoS_Users" {
    name                   = "DoS_Users"
    rest_api_id            = aws_api_gateway_rest_api.DoS_REST.id
    type                   = "COGNITO_USER_POOLS"
    provider_arns          = ["${aws_cognito_user_pool.DoS_Users.arn}"]
    }

resource "aws_api_gateway_authorizer" "Capacity_Management_Users" {
    name                   = "Capacity_Management_Users"
    rest_api_id            = aws_api_gateway_rest_api.DoS_REST.id
    type                   = "COGNITO_USER_POOLS"
    provider_arns          = ["${aws_cognito_user_pool.Capacity_Management_Users.arn}"]
    }


resource "aws_api_gateway_usage_plan" "standard" {
    name         = "standard"
    description  = "Standard Usage Plan"

    api_stages {
        api_id = aws_api_gateway_rest_api.DoS_REST.id
        stage  = aws_api_gateway_stage.main.stage_name
    }

    quota_settings {
        limit  = 20000
        offset = 2
        period = "WEEK"
    }

    throttle_settings {
        burst_limit = 50
        rate_limit  = 100
    }
}


resource "aws_api_gateway_api_key" "example_key" {
    name = "example_key"
    value = "LyXvMVUd3L9bc5IVhpA4l5efM0jqvLFL535MVHpx"
}

resource "aws_api_gateway_usage_plan_key" "main" {
    key_id        = aws_api_gateway_api_key.example_key.id
    key_type      = "API_KEY"
    usage_plan_id = aws_api_gateway_usage_plan.standard.id
}

