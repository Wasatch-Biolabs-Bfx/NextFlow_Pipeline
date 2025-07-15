process MODKIT {
    tag "$curr_req_number"
    label 'process_medium'
    
    container 'community.wave.seqera.io/library/ont-modkit:0.5.0--50865a1a1330dc2b'

    input:
    tuple val(curr_test_type), val(curr_barcode), val(curr_julian_id), val(curr_req_number)
    path input_dir
    path ref_genome
    path ref_motifs

    output:
    tuple val(curr_test_type), val(curr_barcode), val(curr_julian_id), val(curr_req_number), emit: sample_info
    path "versions.yml", emit: versions

    when:
    (task.ext.when == null || task.ext.when) && params.modification == true

    script:
    def args = task.ext.args ?: ''
    """
    batch_dir="\$(realpath ${input_dir})"
    
    # Ensure batch_dir path ends with '/'
    if [[ "\${batch_dir: -1}" != "/" ]]; then
        batch_dir="\${batch_dir}/"
    fi

    echo "Extracting methylation calls for ${curr_req_number}_${curr_julian_id}"

    modkit extract calls \\
        --threads ${task.cpus} \\
        "\${batch_dir}${curr_req_number}_${curr_julian_id}/${curr_req_number}_${curr_julian_id}.aln.sorted.bam" \\
        "\${batch_dir}${curr_req_number}_${curr_julian_id}/${curr_req_number}_${curr_julian_id}.calls.tsv" \\
        --ref ${ref_genome} \\
        --include-bed ${ref_motifs} \\
        --mapped-only \\
        --force \\
        --kmer-size 2 \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        modkit: \$(modkit --version 2>&1 | sed 's/^.*modkit //; s/ .*\$//')
    END_VERSIONS
    """

    stub:
    """
    batch_dir="\$(realpath ${input_dir})"
    if [[ "\${batch_dir: -1}" != "/" ]]; then
        batch_dir="\${batch_dir}/"
    fi
    
    mkdir -p "\${batch_dir}${curr_req_number}_${curr_julian_id}"
    touch "\${batch_dir}${curr_req_number}_${curr_julian_id}/${curr_req_number}_${curr_julian_id}.calls.tsv"
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        modkit: \$(modkit --version 2>&1 | sed 's/^.*modkit //; s/ .*\$//')
    END_VERSIONS
    """
}