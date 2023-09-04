import torch
from transformers import BertTokenizer, BertModel
import timm
import logging
import os
import sys

def check_files_exist_in_subdirectories(directory, file_endings, shared_object_ending):
    if not os.path.exists(directory):
        print(f"ERROR: The directory '{directory}' does not exist.")
        sys.exit(1)

    first_iteration = True
    for subdir, _, files in os.walk(directory):
        print(f">>>Verifying {subdir}")
        if first_iteration:  # To skip the main directory
            first_iteration = False
            continue

        # Check for files with specified endings
        valid_files = [file for file in files if any(file.endswith(ending) for ending in file_endings)]
        
        # Check for .so file
        so_files = [file for file in files if file.endswith(shared_object_ending)]

        if not valid_files and not so_files:
            print(f"ERROR: Missing required files in directory '{subdir}'")
            sys.exit(1)

        print("Found files:")
        print(valid_files)
        print(so_files)

    print("SUCCESS: All required files exist in the subdirectories.")

def example_01():
    def fn(x, y):
        a = torch.cos(x).cuda()
        b = torch.sin(y).cuda()
        return a + b
    new_fn = torch.compile(fn, backend="inductor")
    input_tensor = torch.randn(10000).to(device="cuda:0")
    a = new_fn(input_tensor, input_tensor)

def example_02():
    tokenizer = BertTokenizer.from_pretrained('bert-base-uncased')
    model = BertModel.from_pretrained("bert-base-uncased").to(device="cuda:0")
    model = torch.compile(model, backend="inductor") # This is the only line of code that we changed
    text = "Replace me by any text you'd like."
    encoded_input = tokenizer(text, return_tensors='pt').to(device="cuda:0")
    output = model(**encoded_input)

def example_03():
    torch._logging.set_logs(output_code=True)
    model = timm.create_model('resnext101_32x8d', pretrained=True, num_classes=2)
    opt_model = torch.compile(model, backend="inductor")
    input_batch = torch.randn(64,3,7,7).to('cuda:0')
    model.to('cuda:0')
    opt_model.to('cuda:0')
    opt_model(input_batch)


torch._logging.set_logs(output_code=True)
os.environ["TORCHINDUCTOR_CACHE_DIR"]="cache/example_01"

print("Running example01 (simple)...")
example_01()
print("Running example02 (huggingface - bert)...")
example_02()
print("Running example03 (timm)...")
example_03()
print("Verifying triton codegen was successful...")
check_files_exist_in_subdirectories(os.environ["TORCHINDUCTOR_CACHE_DIR"] + "/triton/0/", ['.amdgcn', '.hsaco_path', '.llir', '.ttgir', '.ttir'], '.so')
