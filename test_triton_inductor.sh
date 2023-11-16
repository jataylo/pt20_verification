#!/bin/bash

set -ex

function kill_and_remove_container() {
    echo "Killing any running container named triton_inductor_testing..."
    docker kill triton_inductor_testing || true
    docker rm triton_inductor_testing || true
}

function pull_docker_image() {
    echo "Pulling latest version of docker image rocm/pytorch-nightly:latest..."
    DOCKER_IMAGE="rocm/pytorch-nightly:latest"
    docker pull ${DOCKER_IMAGE}
}

function run_docker_container() {
    echo "Running docker container rocm/pytorch-nightly:latest..."
    docker run --name triton_inductor_testing -e CI=1 \
        -t -d --network=host --device=/dev/kfd --device=/dev/dri --ipc="host" \
        --pid="host" --shm-size 8G --group-add video --cap-add=SYS_PTRACE \
        --security-opt seccomp=unconfined ${DOCKER_IMAGE} /bin/cat
}

function copy_files_to_container() {
    echo "Copying UT scripts to container..."
    docker cp ${PWD}/examples.py triton_inductor_testing:/root/examples.py
    docker cp ${PWD}/requirements.txt triton_inductor_testing:/root/requirements.txt
}

# Inductor UT list
test_suites=(
    inductor/test_standalone_compile
    inductor/test_torchinductor
    inductor/test_torchinductor_codegen_dynamic_shapes
    inductor/test_torchinductor_dynamic_shapes
    inductor/test_torchinductor_opinfo
)
echo "Inductor test UTs: ${test_suites[*]}"

kill_and_remove_container
pull_docker_image
run_docker_container

# Uninstall and install triton package in image
echo "Uninstalling triton package in image..."
docker exec triton_inductor_testing bash -c "pip3 uninstall -y triton && pip3 uninstall -y pytorch-triton-rocm"

echo "Installing triton package from source..."
docker exec triton_inductor_testing bash -c "mkdir /root/triton && cd /root/triton && git clone https://github.com/ROCmSoftwarePlatform/triton.git && cd triton/python && python3 setup.py develop"

# Run upstream tests from pytorch
echo "Running upstream tests from pytorch..."
docker exec triton_inductor_testing bash -c "cd /root/ && git clone https://github.com/pytorch/pytorch --recursive"
docker exec triton_inductor_testing bash -c "PYTORCH_TEST_WITH_ROCM=1 python3 pytorch/test/run_test.py --continue-through-error --verbose --include ${test_suites[*]} -k cuda 2>&1 | tee test_pytorch_inductor.log"

kill_and_remove_container
