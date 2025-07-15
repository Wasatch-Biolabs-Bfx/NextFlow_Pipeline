process PARSE_JSON {
    tag "$batch_id"
    label 'process_single'
    
    container 'community.wave.seqera.io/library/pip_argparse_requests:9605a07dae1164a2'

    input:
    val batch_id
    path src_dir

    output:
    path "${batch_id}.tsv", emit: samples_tsv
    path "versions.yml"    , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    python ${src_dir}/api_get.py \\
        --batch_id '${batch_id}' \\
        --api_link '${params.api_link_get}' \\
        --auth_key '${params.api_auth_key}' \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """

    stub:
    """
    echo -e "Noa Guide\\t10\\t24-171-0001\\nNoa Guide\\t11\\t24-171-0002" > "${batch_id}.tsv"
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}