#!/user/bin/bash

source venv/bin/activate

# Set environment variables from .env file
export $(grep -v '^#' .env | xargs)