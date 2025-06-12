#!/usr/bin/

process modkit {
    if (params.parallel_processes) {
        maxForks params.parallel_processes.toInteger()
    }

    container = 'community.wave.seqera.io/library/ont-modkit:0.5.0--50865a1a1330dc2b'

    input:
        tuple val(curr_test_type), val(curr_barcode), val(curr_julian_id), val(curr_req_number)
        path input_dir
        path ref_genome
        path ref_motifs

    output:
        tuple val("$curr_test_type"), val("$curr_barcode"), val("$curr_julian_id"), val("$curr_req_number")

    shell:
    """
    if [[ ${params.modification} == true ]];
    then
        batch_dir="\$(realpath ${input_dir})"
        
        # Make sure batch_dir path ends in '/'
        if [[ "\${batch_dir: -1}" != "/" ]]; then
            # Add "/" to the end if it is not present
            batch_dir="\${batch_dir}/"
        fi

        #read_count=\$(samtools view -c \${batch_dir}${curr_req_number}_${curr_julian_id}/${curr_req_number}_${curr_julian_id}.prim.inregion.aln.sorted.bam)

        #if [ "\$read_count" -eq 0 ]; then
        #    echo "prim.inregion.aln.sorted.bam for ${curr_req_number} (${curr_julian_id}) has 0 reads"
        #    touch \${batch_dir}${curr_req_number}_${curr_julian_id}/${curr_req_number}_${curr_julian_id}.calls.tsv

        #else
        echo "Extracting methyl calls for ${curr_req_number} (${curr_julian_id})"

        modkit extract calls\\
            --threads 4 \\
            \${batch_dir}${curr_req_number}_${curr_julian_id}/${curr_req_number}_${curr_julian_id}.aln.sorted.bam \\
            \${batch_dir}${curr_req_number}_${curr_julian_id}/${curr_req_number}_${curr_julian_id}.calls.tsv \\
            --ref ${ref_genome} \\
            --include-bed ${ref_motifs} \\
            --mapped-only --force --kmer-size 2

        # modkit extract \${batch_dir}${curr_req_number}_${curr_julian_id}/${curr_req_number}_${curr_julian_id}.aln.sorted.bam \\
        #    "null" --read-calls \${batch_dir}${curr_req_number}_${curr_julian_id}/${curr_req_number}_${curr_julian_id}.calls.tsv --ref ${params.ref_genome} --include-bed ${params.ref_motifs} --mapped-only --force --kmer-size 2

    else
        echo "Modification parameter was not selected so skipping modkit"
    fi
    """
    // """
    // echo "modkit process"
    // """
}
