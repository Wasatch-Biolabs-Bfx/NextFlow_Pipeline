#!/usr/bin/

process qc {
    if (params.parallel_processes) {
        maxForks params.parallel_processes.toInteger()
    }

    container = 'community.wave.seqera.io/library/samtools_bc:84b8dd4722c957d3'

    input:
        tuple val(curr_test_type), val(curr_barcode), val(curr_julian_id), val(curr_req_number)
    
    output:
        tuple val("$curr_test_type"), val("$curr_barcode"), val("$curr_julian_id"), val("$curr_req_number")

    shell:
    """
    if [[ ${params.align} == true ]] || [[ ${params.modification} == true ]];
    then
        batch_dir=${params.input_dir}
        
        # Make sure batch_dir path ends in '/'
        if [[ "\${batch_dir: -1}" != "/" ]]; then
            # Add "/" to the end if it is not present
            batch_dir="\${batch_dir}/"
        fi

        #ref_seq = \$(basename ${params.ref_genome})
        
        # get alignment stats
        stats_file=\${batch_dir}${curr_req_number}_${curr_julian_id}/${curr_req_number}_${curr_julian_id}_alignment_stats.txt

        echo "## ${curr_req_number}_${curr_julian_id} Alignment Stats ##" > \${stats_file}
        #echo "## Reference \${ref_seq} ##" >> \${stats_file}
        echo "" >> \${stats_file}

        echo "# RUNNING STATS ON BATCH ${curr_req_number}_${curr_julian_id} #"

        aligned_reads=\$(samtools view -F 2308 -c \${batch_dir}/${curr_req_number}_${curr_julian_id}/${curr_req_number}_${curr_julian_id}.aln.sorted.bam)
        total_reads=\$(samtools view -c \${batch_dir}/${curr_req_number}_${curr_julian_id}/${curr_req_number}_${curr_julian_id}.bam)
        alignment_rate=\$(echo "scale=2; \${aligned_reads}*100/\${total_reads}" | bc)

        echo "TOTAL PRIMARY ALIGNED READS: \${aligned_reads}" >> \${stats_file}
        echo "TOTAL READS: \${total_reads}" >> \${stats_file}
        echo "ALIGNMENT RATE: \${alignment_rate}%" >> \${stats_file}

    else
        echo "Neither align or modification parameters selected so skipping alignment qc"
    fi
    """
    // """
    // echo "qc report script"
    // """
}

