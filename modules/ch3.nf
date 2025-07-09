#!/usr/bin/env nextflow

process ch3 {
    if (params.parallel_processes) {
        maxForks params.parallel_processes.toInteger()
    }

    container 'haileyzimmerman/methylseqr:0.8.2'
    containerOptions '--entrypoint ""'     // <<< clears ENTRYPOINT

    input:
        tuple val(curr_test_type), val(curr_barcode), val(curr_julian_id), val(curr_req_number)
        path input_dir

    output:
        tuple val("$curr_test_type"), val("$curr_barcode"), val("$curr_julian_id"), val("$curr_req_number")

    script:
    """
    if [[ ${params.modification} == true ]];
    then
        batch_dir=${input_dir} # {input_dir}
        
        # Make sure batch_dir path ends in '/'
        if [[ "\${batch_dir: -1}" != "/" ]]; then
            # Add "/" to the end if it is not present
            batch_dir="\${batch_dir}/"
        fi

        # Make ch3 file
        echo "Writing to: \${batch_dir}${curr_req_number}_${curr_julian_id}/"
        mkdir -p \${batch_dir}${curr_req_number}_${curr_julian_id}/
        
        echo "Writing CH3 archive..."

        # Run R script
cat > run_make_ch3.R <<'RS'
library(MethylSeqR)
library(dplyr)
library(arrow)

print(Sys.getenv("CALLS_FILE"))
getwd()
make_ch3_archive(
    file_name = Sys.getenv("CALLS_FILE"),
    sample_name = Sys.getenv("SAMPLE_NAME"),
    out_path   = Sys.getenv("OUT_PATH")
)
RS

        CALLS_FILE="\${batch_dir}${curr_req_number}_${curr_julian_id}/${curr_req_number}_${curr_julian_id}.calls.tsv"  \
        SAMPLE_NAME="${curr_req_number}_${curr_julian_id}" \
        OUT_PATH="\${batch_dir}${curr_req_number}_${curr_julian_id}/" \
        Rscript --vanilla run_make_ch3.R


        ## Make new dir and populate with necessary files
        
        # make the dir
        #new_dir="\${batch_dir}${curr_req_number}_${curr_julian_id}/"
        #mkdir -p \${new_dir}

        # move toi output, ubam to dir
        #mv \${batch_dir}${curr_req_number}_${curr_julian_id}/${curr_req_number}_${curr_julian_id}_toi_output.csv \${new_dir}
        #mv \${batch_dir}${curr_req_number}_${curr_julian_id}/${curr_req_number}_${curr_julian_id}_results.csv \${new_dir}
        #mv \${batch_dir}${curr_req_number}_${curr_julian_id}/${curr_req_number}_${curr_julian_id}.bam \${new_dir}

        # copy report to dir as well
        #cp "\${batch_dir}${curr_req_number}_${curr_julian_id}/${curr_req_number}_${curr_julian_id}_qc_report.pdf" \${new_dir}

        # compress dir
        #cd \${batch_dir}${curr_req_number}_${curr_julian_id}
        #tar -czvf ${curr_req_number}_${curr_julian_id}.tar.gz ${curr_req_number}_${curr_julian_id}

    else
        echo "Modification parameter was not selected so skipping ch3"
    fi

    """

    // """
    // echo "make ch3"
    // """
}
