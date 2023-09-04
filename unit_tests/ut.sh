#!/bin/bash

# Clone pytorch
git clone https://github.com/pytorch/pytorch

# Define the test suites
test_suites=(
dynamo/test_aot_autograd
dynamo/test_dynamic_shapes
inductor/test_standalone_compile
inductor/test_torchinductor
inductor/test_torchinductor_codagen_dynamic_shapes
inductor/test_torchinductor_dynamic_shapes
inductor/test_torchinductor_opinfo
)

# Loop through the test suites
for suite in "${test_suites[@]}"
do
    # Run the test suite and redirect the output to a file with the suite name
    PYTORCH_TEST_WITH_ROCM=1 CI=1 python3 pytorch/test/run_test.py -v --continue-through-error -i "$suite" 2>&1 | tee "test_${suite//\//-}.log"
done
