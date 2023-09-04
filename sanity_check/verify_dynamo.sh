#!/bin/bash

# URL of the Python file to download
FILE_URL="https://raw.githubusercontent.com/pytorch/pytorch/main/tools/dynamo/verify_dynamo.py"
OUTPUT_FILE="verify_dynamo.py"

# Function to download the file
download_file() {
    if command -v curl &> /dev/null; then
        curl -O $FILE_URL -o $OUTPUT_FILE
    elif command -v wget &> /dev/null; then
        wget $FILE_URL -O $OUTPUT_FILE
    else
        # Neither curl nor wget is available
        echo "Neither curl nor wget is available."
        read -p "Do you want to install curl? (y/n): " response
        if [[ $response == "y" || $response == "Y" ]]; then
            # Attempt to detect the package manager and install curl
            if command -v apt-get &> /dev/null; then
                apt-get update && apt-get install curl
            elif command -v yum &> /dev/null; then
                yum install curl
            elif command -v brew &> /dev/null; then
                brew install curl
            else
                echo "ERROR: Couldn't detect a known package manager. Please install curl or wget manually."
                exit 1
            fi
            # Try downloading again after installing
            curl -O $FILE_URL -o $OUTPUT_FILE
        else
            echo "Please install curl or wget manually and try again."
            exit 1
        fi
    fi
}

# Download the file
download_file

# Execute the downloaded Python script
python3 $OUTPUT_FILE

# Check the exit code of the Python script
if [ $? -eq 0 ]; then
    echo "SUCCESS: verify_dynamo.py executed successfully!"
    exit 0
else
    echo "ERROR: verify_dynamo.py execution failed."
    exit 1
fi

