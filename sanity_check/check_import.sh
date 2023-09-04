#!/bin/bash

# Try importing the triton module using Python
python3 -c "import triton; import torch; import torch._inductor; import torch._dynamo" 

# Check the exit code of the previous command
if [ $? -eq 0 ]; then
    echo "SUCCESS: Able to import triton in Python!"
    exit 0
else
    echo "ERROR: Unable to import triton in Python!"
    exit 1
fi
