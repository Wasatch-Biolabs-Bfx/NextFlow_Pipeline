#!/usr/bin/

process aws_upload_samples {
    if (params.parallel_processes) {
        maxForks params.parallel_processes.toInteger()
    }

    input:
        tuple val(curr_test_type), val(curr_barcode), val(curr_julian_id), val(curr_req_number)
    
    output:
        tuple val("$curr_test_type"), val("$curr_barcode"), val("$curr_julian_id"), val("$curr_req_number")

    shell:
    """
     batch_dir=${params.input_dir}
    
    # Make sure batch_dir path ends in '/'
    if [[ "\${batch_dir: -1}" != "/" ]]; then
        # Add "/" to the end if it is not present
        batch_dir="\${batch_dir}/"
    fi

    s3_bucket=${params.s3_bucket}

     # Make sure s3 bucket path ends in '/'
    if [[ "\${s3_bucket: -1}" != "/" ]]; then
        # Add "/" to the end if it is not present
        s3_bucket="\${s3_bucket}/"
    fi

    upload_bucket="\${s3_bucket}${params.batch_id}/${curr_req_number}_${curr_julian_id}/" # make sure to put the '/' at the end

    #qc_file="\${batch_dir}${curr_req_number}_${curr_julian_id}/${curr_req_number}_${curr_julian_id}_qc_report.html"
    qc_file="\${batch_dir}${curr_req_number}_${curr_julian_id}/${curr_req_number}_${curr_julian_id}_alignment_stats.txt"
    data_archive="\${batch_dir}${curr_req_number}_${curr_julian_id}.tar"

    # upload sample qc file
    aws s3 cp \${qc_file} \${upload_bucket}

    if [ \$? -eq 0 ]; then
        echo "Successfully uploaded \${qc_file} to \${upload_bucket}"
    else
        echo "Failed to upload \${qc_file} to \${upload_bucket}"
    fi

    # upload sample data
    aws s3 cp \${data_archive} \${upload_bucket}

    if [ \$? -eq 0 ]; then
        echo "Successfully uploaded \${data_archive} to \${upload_bucket}"
    else
        echo "Failed to upload \${data_archive} to \${upload_bucket}"
    fi

     """
    // """
    // echo "upload sample data"
    // """
}
