#!/bin/bash

# Set up environment
export PYTHONPATH=/app:$PYTHONPATH

# Print welcome message
echo "Welcome to FastAgent Console"
echo "Type your queries or commands at the prompt"
echo "Type 'exit', 'quit', or 'q' to exit the console"
echo ""

# Run the agent
python3 /app/agent.py

# Exit message
echo ""
echo "FastAgent session ended."