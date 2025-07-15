process ALIGN {
    tag "$curr_req_number"
    label 'process_high'
    
    container 'community.wave.seqera.io/library/samtools_dorado:4d022fe2bdea3beb'

    input:
    tuple val(curr_test_type), val(curr_barcode), val(curr_julian_id), val(curr_req_number)
    path input_dir
    path ref_genome

    output:
    tuple val(curr_test_type), val(curr_barcode), val(curr_julian_id), val(curr_req_number), emit: sample_info
    path "versions.yml", emit: versions

    when:
    (task.ext.when == null || task.ext.when) && (params.align == true || params.modification == true)

    script:
    def args = task.ext.args ?: ''
    """
    echo "Memory limit: \$(ulimit -a)"
    free -h

    sample_dir="${input_dir}/${curr_req_number}_${curr_julian_id}"

    echo "Aligning ${curr_req_number}_${curr_julian_id} (barcode: ${curr_barcode}, test_type: ${curr_test_type})"
    
    # Alignment
    dorado aligner \\
        ${ref_genome} \\
        "\${sample_dir}/${curr_req_number}_${curr_julian_id}.bam" \\
        ${args} \\
        > "\${sample_dir}/${curr_req_number}_${curr_julian_id}.aln.bam"

    # Sorting
    echo "Sorting aligned BAM for ${curr_req_number}_${curr_julian_id}"
    samtools sort \\
        "\${sample_dir}/${curr_req_number}_${curr_julian_id}.aln.bam" \\
        > "\${sample_dir}/${curr_req_number}_${curr_julian_id}.aln.sorted.bam"

    # Indexing
    echo "Indexing sorted aligned BAM for ${curr_req_number}_${curr_julian_id}"
    samtools index \\
        "\${sample_dir}/${curr_req_number}_${curr_julian_id}.aln.sorted.bam" \\
        "\${sample_dir}/${curr_req_number}_${curr_julian_id}.aln.sorted.bam.bai"

    # Cleanup
    echo "Removing intermediate files for ${curr_req_number}_${curr_julian_id}"
    rm -f "\${sample_dir}/${curr_req_number}_${curr_julian_id}.aln.bam"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        dorado: \$(dorado --version 2>&1 | head -n1 | sed 's/^.*dorado //; s/ .*\$//')
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """

    stub:
    """
    sample_dir="${input_dir}/${curr_req_number}_${curr_julian_id}"
    mkdir -p "\${sample_dir}"
    touch "\${sample_dir}/${curr_req_number}_${curr_julian_id}.aln.sorted.bam"
    touch "\${sample_dir}/${curr_req_number}_${curr_julian_id}.aln.sorted.bam.bai"
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        dorado: \$(dorado --version 2>&1 | head -n1 | sed 's/^.*dorado //; s/ .*\$//')
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """
}