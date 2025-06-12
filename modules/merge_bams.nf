#!/usr/bin/

process merge_bams {
    if (params.parallel_processes) {
        maxForks params.parallel_processes.toInteger()
    }

    container 'community.wave.seqera.io/library/samtools:1.21--0d76da7c3cf7751c'

    input:
        tuple val(curr_test_type), val(curr_barcode), val(curr_julian_id), val(curr_req_number)
        path input_dir
    
    output:
        tuple val("$curr_test_type"), val("$curr_barcode"), val("$curr_julian_id"), val("$curr_req_number")

    script:
    """

    sample_dir="${input_dir}/${curr_req_number}_${curr_julian_id}"

    if [ ! -d "\${sample_dir}" ]; then
        mkdir "\${sample_dir}"
    fi

    if [ "${curr_barcode}" == "None" ]; then
        ##############
        # merge bams #
        ##############
        echo "Merging all bams"
        samtools merge -f "\${sample_dir}/${curr_req_number}_${curr_julian_id}.bam" "${input_dir}/bam_pass/"*.bam
    else
        ##############
        # merge bams #
        ##############
        echo "Merging barcode${curr_barcode} bams"
        samtools merge -f "\${sample_dir}/${curr_req_number}_${curr_julian_id}.bam" "${input_dir}/bam_pass/barcode${curr_barcode}/"*.bam
    fi

    """
    // """
    // echo "merge bams ($curr_req_number)"
    // """
}