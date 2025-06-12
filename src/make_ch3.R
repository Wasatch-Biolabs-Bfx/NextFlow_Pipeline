## dependencies
library(arrow)
library(dplyr)
library(readr)
library(stringr)

# Get command-line arguments (excluding the script name)
args = commandArgs(trailingOnly = TRUE)

print("into args")
# Check if exactly two arguments are provided
if (length(args) != 4) {
  cat("Usage: Rscript script.R <path to script> <path to calls file> <output file path> <sample name>\n")
  stop("Error: Exactly 4 arguments are required.", call. = FALSE)
}

# Assign arguments to variables
print("getting vars")
make_ch3_script = args[1]
calls_file_path = args[2]
output_path = args[3]
sample_name = args[4]

print("sourcing")
print(make_ch3_script)
source(make_ch3_script)

## MAKE CH3
print(paste0("making .ch3 for: ",sample_name))

# Ensure the output path exists
if (!dir.exists(output_path)) {
  dir.create(output_path, recursive = TRUE)
}

make_ch3_archive(file_name = calls_file_path, 
                 sample_name = sample_name, 
                 out_path = output_path)
