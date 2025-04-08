#!/bin/bash

# Set up environment
export PYTHONPATH=/app:$PYTHONPATH

# Log in to ECR Public if credentials are provided
if [ -n "$AWS_ACCESS_KEY_ID" ] && [ -n "$AWS_SECRET_ACCESS_KEY" ]; then
  echo "Authenticating with AWS ECR Public..."
  aws ecr-public get-login-password --region ${AWS_DEFAULT_REGION:-us-east-1} | docker login --username AWS --password-stdin public.ecr.aws
fi

# Print welcome message
echo "Welcome to Fat Zebra AI"
echo "Type your queries or commands at the prompt"
echo "Type 'exit', 'quit', or 'q' to exit the console"
echo ""

# Run the agent
python3 /app/agent.py

# Exit message
echo ""
echo "FastAgent session ended."