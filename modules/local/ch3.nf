process CH3 {
    tag "$curr_req_number"
    label 'process_medium'
    
    container 'haileyzimmerman/methylseqr:0.8.2'
    containerOptions '--entrypoint ""'

    input:
    tuple val(curr_test_type), val(curr_barcode), val(curr_julian_id), val(curr_req_number)
    path input_dir

    output:
    tuple val(curr_test_type), val(curr_barcode), val(curr_julian_id), val(curr_req_number), emit: sample_info
    path "versions.yml", emit: versions

    when:
    (task.ext.when == null || task.ext.when) && params.modification == true

    script:
    def args = task.ext.args ?: ''
    """
    batch_dir=${input_dir}
    
    # Ensure batch_dir path ends with '/'
    if [[ "\${batch_dir: -1}" != "/" ]]; then
        batch_dir="\${batch_dir}/"
    fi

    echo "Writing CH3 archive for ${curr_req_number}_${curr_julian_id}"
    echo "Output directory: \${batch_dir}${curr_req_number}_${curr_julian_id}/"
    
    mkdir -p "\${batch_dir}${curr_req_number}_${curr_julian_id}/"

    # Create R script for CH3 archive generation
    cat > run_make_ch3.R <<'RS'
library(MethylSeqR)
library(dplyr)
library(arrow)

print(paste("Processing calls file:", Sys.getenv("CALLS_FILE")))
print(paste("Working directory:", getwd()))

make_ch3_archive(
    file_name = Sys.getenv("CALLS_FILE"),
    sample_name = Sys.getenv("SAMPLE_NAME"),
    out_path = Sys.getenv("OUT_PATH")
)

print("CH3 archive creation completed")
RS

    # Set environment variables and run R script
    CALLS_FILE="\${batch_dir}${curr_req_number}_${curr_julian_id}/${curr_req_number}_${curr_julian_id}.calls.tsv" \\
    SAMPLE_NAME="${curr_req_number}_${curr_julian_id}" \\
    OUT_PATH="\${batch_dir}${curr_req_number}_${curr_julian_id}/" \\
    Rscript --vanilla run_make_ch3.R

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        R: \$(R --version | head -n1 | sed 's/R version //; s/ (.*\$//')
        MethylSeqR: \$(Rscript -e "cat(as.character(packageVersion('MethylSeqR')))" 2>/dev/null || echo "unknown")
    END_VERSIONS
    """

    stub:
    """
    batch_dir=${input_dir}
    if [[ "\${batch_dir: -1}" != "/" ]]; then
        batch_dir="\${batch_dir}/"
    fi
    
    mkdir -p "\${batch_dir}${curr_req_number}_${curr_julian_id}/"
    touch "\${batch_dir}${curr_req_number}_${curr_julian_id}/${curr_req_number}_${curr_julian_id}.ch3"
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        R: \$(R --version | head -n1 | sed 's/R version //; s/ (.*\$//')
        MethylSeqR: \$(Rscript -e "cat(as.character(packageVersion('MethylSeqR')))" 2>/dev/null || echo "unknown")
    END_VERSIONS
    """
}