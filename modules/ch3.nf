#!/usr/bin/

process ch3 {
    if (params.parallel_processes) {
        maxForks params.parallel_processes.toInteger()
    }

    container 'community.wave.seqera.io/library/r-dplyr_r-readr_r-stringr_r-arrow_r-base:a78bd5af1f5aadcf'
    // Maybe make just an R-base container and install other R packages?
    input:
        tuple val(curr_test_type), val(curr_barcode), val(curr_julian_id), val(curr_req_number)
        path input_dir
        path call_ch3_script
        path ch3_script

    output:
        tuple val("$curr_test_type"), val("$curr_barcode"), val("$curr_julian_id"), val("$curr_req_number")

    shell:
    """
    if [[ ${params.modification} == true ]];
    then
        batch_dir=\$PWD # {input_dir}
        
        # Make sure batch_dir path ends in '/'
        if [[ "\${batch_dir: -1}" != "/" ]]; then
            # Add "/" to the end if it is not present
            batch_dir="\${batch_dir}/"
        fi

        # Make ch3 file
        echo "Writing to: \${batch_dir}${curr_req_number}_${curr_julian_id}/"
        mkdir -p \${batch_dir}${curr_req_number}_${curr_julian_id}/

        Rscript ${call_ch3_script} \
            ${ch3_script} \
            \${batch_dir}${curr_req_number}_${curr_julian_id}/${curr_req_number}_${curr_julian_id}.calls.tsv \
            \${batch_dir}${curr_req_number}_${curr_julian_id}/ \
            ${curr_req_number}_${curr_julian_id}

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
