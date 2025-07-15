process API_POST {
    tag "$batch_id"
    label 'process_single'
    
    container 'community.wave.seqera.io/library/pip_argparse_requests:9605a07dae1164a2'

    input:
    val batch_id
    path script

    output:
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    echo "Posting completion status for batch ${batch_id} to API"
    
    python ${projectDir}/src/api_post.py \\
        --batch_id '${batch_id}' \\
        --api_link_get '${params.api_link_get}' \\
        --api_link_post '${params.api_link_post}' \\
        --auth_key '${params.api_auth_key}' \\
        ${args}

    echo "Finished API post for batch ${batch_id}"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """

    stub:
    """
    echo "Would post completion status for batch ${batch_id}"
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}