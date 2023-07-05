#!/bin/bash

#THIS SCRIPT EXECUTES THE RELEVANT DEPLOYMENT ACTIONS FOR THIS MICROSERVICE.
#IT IS REFERENCED BY THE APPLICATION PIPELINE AND THEREFORE MUST ALWAYS BE CALLED "deploy_service.sh"    

#INPUT ARGUMENTS

SERVICE_NAME=$1
ENVIRONMENT_NAME=$2

npm install
npm run build
cd ./build
aws s3 cp . s3://frontend-bucket180122022 --recursive