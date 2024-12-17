#!/usr/bin/env bash

# This script shows how to build the Docker image and push it to ECR to be ready for use
# by SageMaker.

# The argument to this script is the image name. This will be used as the image on the local
# machine and combined with the account and region to form the repository name for ECR.
image=$1

if [ "$image" == "" ]
then
    echo "Usage: $0 <image-name>"
    exit 1
fi


# Get the account number associated with the current IAM credentials
account=$(aws sts get-caller-identity --query Account --output text)

if [ $? -ne 0 ]
then
    exit 255
fi

# Get the region defined in the current configuration (default to us-west-2 if none defined)
region=$(aws configure get region)
region=${region:-us-west-2}

# If the repository doesn't exist in ECR, create it.

aws ecr describe-repositories --repository-names "${image}" > /dev/null 2>&1

if [ $? -ne 0 ]
then
    aws ecr create-repository --repository-name "${image}" > /dev/null
fi

# Authenticate Docker to push to ECR
ecr_registry="${account}.dkr.ecr.${region}.amazonaws.com"
aws ecr get-login-password --region "${region}" \
    | docker login --username AWS --password-stdin "${ecr_registry}"

# Build the docker image locally with the image name
DOCKER_BUILDKIT=0 docker build -t "${image}:latest" .

# Tag the image with the full name and latest
fullname="${ecr_registry}/${image}:latest"
docker tag ${image} ${fullname}

# Push the image to ECR
docker push ${fullname}
