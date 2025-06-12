#!/usr/bin/

process organize_data {
    if (params.parallel_processes) {
        maxForks params.parallel_processes.toInteger()
    }

    input:
        tuple val(curr_test_type), val(curr_barcode), val(curr_julian_id), val(curr_req_number)
    
    output:
        tuple val("$curr_test_type"), val("$curr_barcode"), val("$curr_julian_id"), val("$curr_req_number")

    shell:
    """
    batch_dir=${params.input_dir}
    
    # Make sure batch_dir path ends in '/'
    if [[ "\${batch_dir: -1}" != "/" ]]; then
        # Add "/" to the end if it is not present
        batch_dir="\${batch_dir}/"
    fi

    # tar-ing dir
    echo "compressing \${batch_dir}${curr_req_number}_${curr_julian_id}"
    tar -cvf \${batch_dir}${curr_req_number}_${curr_julian_id}.tar \${batch_dir}${curr_req_number}_${curr_julian_id}/

    """

    // """
    // echo "organize data"
    // """
}
