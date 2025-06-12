#!/usr/bin/

process aws_upload_batch {
    input:
        val batch_id
        val all_results // not used here but makes sure this is executed after everything has completed
    output:
        val "${batch_id}"

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

    upload_bucket="\${s3_bucket}${params.batch_id}/" # make sure to put the '/' at the end

    batch_qc_file=\$(find "\${batch_dir}" -type f -name "report_*.html" -print -quit)

    # Check if a file was found and print the result
    if [ -z "\${batch_qc_file}" ]; then
        echo "No batch QC file found"
    fi

    # rename batch qc file
    cp \${batch_qc_file} \${batch_dir}${params.batch_id}_run_report.html

    # upload batch qc file
    aws s3 cp \${batch_dir}${params.batch_id}_run_report.html \${upload_bucket}

    if [ \$? -eq 0 ]; then
        echo "Successfully uploaded ${params.batch_id}_run_report.html to \${upload_bucket}"
    else
        echo "Failed to upload ${params.batch_id}_run_report.html to \${upload_bucket}"
    fi
    """
}
