#!/bin/bash

execute_with_prefix() {
    local prefix="$1"
    local cmd="$2"
    $cmd 2>&1 | while read -r line; do
        echo "[$prefix] $line"
    done
    return ${PIPESTATUS[0]}
}

sanity_check() {
    local passed=0
    local failed=0

    # Check if triton package is installed
    execute_with_prefix "pt20_verification: sanity_check - check_pip" "sanity_check/check_pip.sh"
    if [ $? -eq 0 ]; then
        ((passed++))
    else
        ((failed++))
        echo "[pt20_verification: sanity_check] ERROR: Triton package is not installed."
    fi

    # Check python import
    execute_with_prefix "pt20_verification: sanity_check - check_import" "sanity_check/check_import.sh"
    if [ $? -eq 0 ]; then
        ((passed++))
    else
        ((failed++))
        echo "[pt20_verification: sanity_check] ERROR: Failed to import Triton in Python."
    fi

    # Verify dynamo - only run in ROCm env
    if [[ -n $ROCM_HOME ]]; then
        execute_with_prefix "pt20_verification: sanity_check - verify_dynamo" "sanity_check/verify_dynamo.sh"
        if [ $? -eq 0 ]; then
            ((passed++))
        else
            ((failed++))
            echo "[pt20_verification: sanity_check] ERROR: verify_dynamo.py execution failed."
        fi
    else
        echo "[pt20_verification: sanity_check] INFO: Skipping verify_dynamo. ROCM_HOME not set."
    fi

    echo "[pt20_verification: sanity_check] ----------------------------"
    echo "[pt20_verification: sanity_check] SANITY TEST SUMMARY:"
    echo "[pt20_verification: sanity_check] Passed: $passed"
    echo "[pt20_verification: sanity_check] Failed: $failed"

    return $failed
}

functionality_check() {
    local passed=0
    local failed=0

    echo "[pt20_verification: functionality] Running functionality check..."

    execute_with_prefix "pt20_verification: examples" "python3 getting_started/examples.py"
    if [ $? -eq 0 ]; then
        ((passed++))
        echo "[pt20_verification: functionality] SUCCESS: Functionality check passed!"
    else
        ((failed++))
        echo "[pt20_verification: functionality] ERROR: Functionality check failed."
    fi

    echo "[pt20_verification: functionality] ----------------------------"
    echo "[pt20_verification: functionality] FUNCTIONALITY TEST SUMMARY:"
    echo "[pt20_verification: functionality] Passed: $passed"
    echo "[pt20_verification: functionality] Failed: $failed"

    return $failed
}

# Install requirements
python3 -m pip install -r requirements.txt

# Flag to determine if any check was executed
checks_run=false

# Check if --sanity_check flag is provided
for arg in "$@"; do
    if [[ "$arg" == "--sanity_check" ]]; then
        sanity_check
        checks_run=true
    elif [[ "$arg" == "--functionality_check" ]]; then
        functionality_check
    	checks_run=true
    fi
done

# If no recognized flags are provided, display usage message
if [ "$checks_run" = false ]; then
    echo "Usage: $0 [--sanity_check] [--functionality_check]"
    echo "Use --sanity_check to run the sanity checks."
    echo "Use --functionality_check to run the functionality checks."
fi
