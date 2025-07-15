process MERGE_BAMS {
    tag "$curr_req_number"
    label 'process_medium'
    
    container 'community.wave.seqera.io/library/samtools:1.21--0d76da7c3cf7751c'

    input:
    tuple val(curr_test_type), val(curr_barcode), val(curr_julian_id), val(curr_req_number)
    path input_dir

    output:
    tuple val(curr_test_type), val(curr_barcode), val(curr_julian_id), val(curr_req_number), emit: sample_info
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    sample_dir="${input_dir}/${curr_req_number}_${curr_julian_id}"

    if [ ! -d "\${sample_dir}" ]; then
        mkdir -p "\${sample_dir}"
    fi

    if [ "${curr_barcode}" == "None" ]; then
        echo "Merging all bams for ${curr_req_number}_${curr_julian_id}"
        samtools merge \\
            ${args} \\
            -f "\${sample_dir}/${curr_req_number}_${curr_julian_id}.bam" \\
            "${input_dir}/bam_pass/"*.bam
    else
        echo "Merging barcode${curr_barcode} bams for ${curr_req_number}_${curr_julian_id}"
        samtools merge \\
            ${args} \\
            -f "\${sample_dir}/${curr_req_number}_${curr_julian_id}.bam" \\
            "${input_dir}/bam_pass/barcode${curr_barcode}/"*.bam
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """

    stub:
    """
    sample_dir="${input_dir}/${curr_req_number}_${curr_julian_id}"
    mkdir -p "\${sample_dir}"
    touch "\${sample_dir}/${curr_req_number}_${curr_julian_id}.bam"
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """
}