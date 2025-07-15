process ORGANIZE_DATA {
    tag "$curr_req_number"
    label 'process_low'

    input:
    tuple val(curr_test_type), val(curr_barcode), val(curr_julian_id), val(curr_req_number)
    path input_dir

    output:
    tuple val(curr_test_type), val(curr_barcode), val(curr_julian_id), val(curr_req_number), emit: sample_info
    path "*.tar", emit: tar_files, optional: true
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    batch_dir=${input_dir}
    
    # Ensure batch_dir path ends with '/'
    if [[ "\${batch_dir: -1}" != "/" ]]; then
        batch_dir="\${batch_dir}/"
    fi

    echo "Compressing data for ${curr_req_number}_${curr_julian_id}"
    
    # Create tar archive of sample directory
    tar -cvf "${curr_req_number}_${curr_julian_id}.tar" \\
        -C "\${batch_dir}" \\
        "${curr_req_number}_${curr_julian_id}/" \\
        ${args}

    # Move tar file to the batch directory
    mv "${curr_req_number}_${curr_julian_id}.tar" "\${batch_dir}${curr_req_number}_${curr_julian_id}.tar"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        tar: \$(tar --version | head -n1 | sed 's/tar (GNU tar) //; s/ .*\$//')
    END_VERSIONS
    """

    stub:
    """
    touch "${curr_req_number}_${curr_julian_id}.tar"
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        tar: \$(tar --version | head -n1 | sed 's/tar (GNU tar) //; s/ .*\$//')
    END_VERSIONS
    """
}