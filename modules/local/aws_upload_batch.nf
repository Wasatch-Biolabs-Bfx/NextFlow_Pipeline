process AWS_UPLOAD_BATCH {
    tag "$batch_id"
    label 'process_single'

    input:
    val batch_id
    val all_results

    output:
    val batch_id, emit: batch_id
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    batch_dir=${params.input_dir}
    
    # Ensure batch_dir path ends with '/'
    if [[ "\${batch_dir: -1}" != "/" ]]; then
        batch_dir="\${batch_dir}/"
    fi

    s3_bucket=${params.s3_bucket}

    # Ensure s3_bucket path ends with '/'
    if [[ "\${s3_bucket: -1}" != "/" ]]; then
        s3_bucket="\${s3_bucket}/"
    fi

    upload_bucket="\${s3_bucket}${batch_id}/"

    echo "Uploading batch-level data for ${batch_id} to S3"

    # Find and upload batch QC report
    batch_qc_file=\$(find "\${batch_dir}" -type f -name "report_*.html" -print -quit)

    if [ -n "\${batch_qc_file}" ]; then
        # Copy and rename batch QC file
        cp "\${batch_qc_file}" "\${batch_dir}${batch_id}_run_report.html"

        # Upload batch QC file
        aws s3 cp \\
            "\${batch_dir}${batch_id}_run_report.html" \\
            "\${upload_bucket}${batch_id}_run_report.html" \\
            ${args}

        if [ \$? -eq 0 ]; then
            echo "Successfully uploaded ${batch_id}_run_report.html"
        else
            echo "Failed to upload ${batch_id}_run_report.html"
            exit 1
        fi
    else
        echo "Warning: No batch QC file found"
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        aws-cli: \$(aws --version | sed 's/aws-cli\\///; s/ .*\$//')
    END_VERSIONS
    """

    stub:
    """
    echo "Would upload batch data for ${batch_id}"
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        aws-cli: \$(aws --version | sed 's/aws-cli\\///; s/ .*\$//')
    END_VERSIONS
    """
}