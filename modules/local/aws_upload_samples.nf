process AWS_UPLOAD_SAMPLES {
    tag "$curr_req_number"
    label 'process_single'

    input:
    tuple val(curr_test_type), val(curr_barcode), val(curr_julian_id), val(curr_req_number)

    output:
    tuple val(curr_test_type), val(curr_barcode), val(curr_julian_id), val(curr_req_number), emit: sample_info
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

    upload_bucket="\${s3_bucket}${params.batch_id}/"

    echo "Uploading sample data for ${curr_req_number}_${curr_julian_id} to S3"

    # Upload tar file
    if [ -f "\${batch_dir}${curr_req_number}_${curr_julian_id}.tar" ]; then
        aws s3 cp \\
            "\${batch_dir}${curr_req_number}_${curr_julian_id}.tar" \\
            "\${upload_bucket}${curr_req_number}_${curr_julian_id}/${curr_req_number}_${curr_julian_id}.tar" \\
            ${args}
        
        if [ \$? -eq 0 ]; then
            echo "Successfully uploaded ${curr_req_number}_${curr_julian_id}.tar"
        else
            echo "Failed to upload ${curr_req_number}_${curr_julian_id}.tar"
            exit 1
        fi
    else
        echo "Warning: Tar file not found for ${curr_req_number}_${curr_julian_id}"
    fi

    # Upload alignment stats
    if [ -f "\${batch_dir}${curr_req_number}_${curr_julian_id}/${curr_req_number}_${curr_julian_id}_alignment_stats.txt" ]; then
        aws s3 cp \\
            "\${batch_dir}${curr_req_number}_${curr_julian_id}/${curr_req_number}_${curr_julian_id}_alignment_stats.txt" \\
            "\${upload_bucket}${curr_req_number}_${curr_julian_id}/${curr_req_number}_${curr_julian_id}_alignment_stats.txt" \\
            ${args}
        
        if [ \$? -eq 0 ]; then
            echo "Successfully uploaded ${curr_req_number}_${curr_julian_id}_alignment_stats.txt"
        else
            echo "Failed to upload ${curr_req_number}_${curr_julian_id}_alignment_stats.txt"
            exit 1
        fi
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        aws-cli: \$(aws --version | sed 's/aws-cli\\///; s/ .*\$//')
    END_VERSIONS
    """

    stub:
    """
    echo "Would upload sample data for ${curr_req_number}_${curr_julian_id}"
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        aws-cli: \$(aws --version | sed 's/aws-cli\\///; s/ .*\$//')
    END_VERSIONS
    """
}