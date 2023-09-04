#!/bin/bash

# Get the pip list output
pip_list=$(pip list | grep -E "triton")

# Check for "pytorch-triton-rocm" or "triton"
if echo "$pip_list" | grep -q "pytorch-triton-rocm"; then
    version=$(echo "$pip_list" | grep "pytorch-triton-rocm" | awk '{print $2}')
    echo "SUCCESS: pytorch-triton-rocm version $version is found!"
elif echo "$pip_list" | grep -q "^triton "; then
    version=$(echo "$pip_list" | grep "^triton " | awk '{print $2}')
    echo "WARNING: triton is either built from source or package name has been incorrectly named in the wheel."
    echo "SUCCESS: triton version $version is found!"
else
    echo "ERROR: cannot find triton package. Please check on triton installation."
fi

