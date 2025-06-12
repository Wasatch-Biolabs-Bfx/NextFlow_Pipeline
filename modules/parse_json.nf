#!/usr/bin/

process parse_json {
    
    container 'community.wave.seqera.io/library/pip_argparse_requests:9605a07dae1164a2'

    input:
        val batch_id
        path src_dir

    output:
        path ( "${params.batch_id}.tsv" )

    script:
    """
    python ${src_dir}/api_get.py --batch_id '${batch_id}' --api_link '${params.api_link_get}' --auth_key '${params.api_auth_key}'
    """

    // Output to use for testing purposes without needing to hit the API
    // """
    // echo -e "Noa Guide\t10\t24-171-0001\nNoa Guide\t11\t24-171-0002" > "${params.batch_id}.tsv"
    // """
}