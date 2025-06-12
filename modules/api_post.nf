#!/usr/bin/

process api_post {
    input:
        val batch_id

    script:
    """
    python ${projectDir}/src/api_post.py --batch_id '${params.batch_id}' --api_link_get '${params.api_link_get}' --api_link_post '${params.api_link_post}' --auth_key '${params.api_auth_key}'
    echo "Finished api_post"
    """
}