process QC {
    tag "$curr_req_number"
    label 'process_low'
    
    container 'community.wave.seqera.io/library/samtools_bc:84b8dd4722c957d3'

    input:
    tuple val(curr_test_type), val(curr_barcode), val(curr_julian_id), val(curr_req_number)
    path input_dir

    output:
    tuple val(curr_test_type), val(curr_barcode), val(curr_julian_id), val(curr_req_number), emit: sample_info
    path "*_alignment_stats.txt", emit: stats, optional: true
    path "versions.yml", emit: versions

    when:
    (task.ext.when == null || task.ext.when) && (params.align == true || params.modification == true)

    script:
    def args = task.ext.args ?: ''
    """
    batch_dir=${input_dir}
    
    # Ensure batch_dir path ends with '/'
    if [[ "\${batch_dir: -1}" != "/" ]]; then
        batch_dir="\${batch_dir}/"
    fi

    echo "Generating QC stats for ${curr_req_number}_${curr_julian_id}"

    # Generate alignment statistics
    stats_file="\${batch_dir}${curr_req_number}_${curr_julian_id}/${curr_req_number}_${curr_julian_id}_alignment_stats.txt"

    echo "## ${curr_req_number}_${curr_julian_id} Alignment Stats ##" > "\${stats_file}"
    echo "" >> "\${stats_file}"

    # Calculate alignment statistics
    aligned_reads=\$(samtools view -F 2308 -c "\${batch_dir}${curr_req_number}_${curr_julian_id}/${curr_req_number}_${curr_julian_id}.aln.sorted.bam")
    total_reads=\$(samtools view -c "\${batch_dir}${curr_req_number}_${curr_julian_id}/${curr_req_number}_${curr_julian_id}.bam")
    
    if [ "\${total_reads}" -gt 0 ]; then
        alignment_rate=\$(echo "scale=2; \${aligned_reads}*100/\${total_reads}" | bc)
    else
        alignment_rate="0.00"
    fi

    echo "TOTAL PRIMARY ALIGNED READS: \${aligned_reads}" >> "\${stats_file}"
    echo "TOTAL READS: \${total_reads}" >> "\${stats_file}"
    echo "ALIGNMENT RATE: \${alignment_rate}%" >> "\${stats_file}"

    # Copy stats file to working directory for output
    cp "\${stats_file}" "${curr_req_number}_${curr_julian_id}_alignment_stats.txt"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
        bc: \$(bc --version | head -n1 | sed 's/bc //; s/ .*\$//')
    END_VERSIONS
    """

    stub:
    """
    touch "${curr_req_number}_${curr_julian_id}_alignment_stats.txt"
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
        bc: \$(bc --version | head -n1 | sed 's/bc //; s/ .*\$//')
    END_VERSIONS
    """
}