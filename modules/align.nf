#!/usr/bin/

process align {
    if (params.parallel_processes) {
        maxForks params.parallel_processes.toInteger()
    }

    // Add memory and CPU resources
    memory '96.GB'  // Adjust based on your system
    errorStrategy 'retry'
    maxRetries 2

    // conda "bioconda::samtools=1.17"
    container 'community.wave.seqera.io/library/samtools_dorado:4d022fe2bdea3beb'

    input:
        tuple val(curr_test_type), val(curr_barcode), val(curr_julian_id), val(curr_req_number)
        path input_dir
        path ref_genome
    
    output:
        tuple val("$curr_test_type"), val("$curr_barcode"), val("$curr_julian_id"), val("$curr_req_number")

    script:
    """
    echo "Memory limit: \$(ulimit -a)" # View imposed resource limits
    free -h                           # View actual available memory


    if [[ ${params.align} == true ]] || [[ ${params.modification} == true ]];
    then
    
        sample_dir="${input_dir}/${curr_req_number}_${curr_julian_id}"

        #############
        # align bam #
        #############

        echo "Aligning barcode${curr_barcode} (req_number: ${curr_req_number}; julian_id: ${curr_julian_id}; test_type: ${curr_test_type})"
        
        dorado aligner \
            ${ref_genome} \
            \${sample_dir}/${curr_req_number}_${curr_julian_id}.bam > \${sample_dir}/${curr_req_number}_${curr_julian_id}.aln.bam


        ###########
        # sorting #
        ###########

        # sorting
        echo "Sorting barcode${curr_barcode} aligned bam"
        samtools sort \${sample_dir}/${curr_req_number}_${curr_julian_id}.aln.bam > \${sample_dir}/${curr_req_number}_${curr_julian_id}.aln.sorted.bam

        # indexing
        echo "Sorting barcode${curr_barcode} sorted aligned in region bam"
        samtools index \${sample_dir}/${curr_req_number}_${curr_julian_id}.aln.sorted.bam \${sample_dir}/${curr_req_number}_${curr_julian_id}.aln.sorted.bam.bai

        # remove unsorted/aligned/in_region bam
        echo "Removing aligned, unsorted bam for barcode${curr_barcode}"
        rm -f \${sample_dir}/${curr_req_number}_${curr_julian_id}.aln.bam

    else
        echo "Neither align or modification parameters selected so skipping alignment"
    fi
    """
    // """
    // echo "align bams"
    // """
}
