#!/usr/bin/

/*
* This main pipeline will parse GET API response and process each sample according
* each sample according to it's declared test type.
*/

/*
* Help message function
*/
params.help = false
def helpMessage() {
    log.info"""
    ================================================================
    W B L - A U T O M A T E D  P I P E L I N E S
    ================================================================
    DESCRIPTION
    Usage:
    nextflow run main.nf --input_dir <input dir> --batch_id <batch id>

    Required options:
        --input_dir        	e.g. /path/to/batch/dir/240606-G
        --batch_id          e.g. 240606-G           

    Pipeline output is deposited in the 'input_dir'      

    """.stripIndent()
}

if (params.help) {
    helpMessage()
    exit 0
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    WBL MAIN NEXTFLOW PIPELINE
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

/*
* Declare Permanent Parameters
*/

// run in parallel or sequentially
params.parallel_processes = null  // Default to parallel processing
params.align = true
params.modification = true

// modules to include (all the steps)
include { parse_json } from './modules/parse_json.nf'
include { merge_bams } from './modules/merge_bams.nf'
include { align } from './modules/align.nf'
include { modkit } from './modules/modkit.nf'
include { ch3 } from './modules/ch3.nf'
include { qc } from './modules/qc.nf'
include { organize_data } from './modules/organize_data.nf'
include { aws_upload_samples } from './modules/aws_upload_samples.nf'
include { aws_upload_batch } from './modules/aws_upload_batch.nf'
include { api_post } from './modules/api_post.nf'

// version
params.version="v0.0.0"

log.info """\
         W B L - A U T O M A T E D  P I P E L I N E S
    """
    .stripIndent(true)
log.info ""
log.info " Declared Parameters "
log.info " ======================"
log.info " Input Directory          : ${params.input_dir}"
log.info " Batch ID                 : ${params.batch_id}"
log.info " ======================"
log.info " Permanent Parameters "
log.info " ======================"
log.info " Dorado Directory         : ${params.dorado_executable_dir}"
log.info " MODKIT Directory         : ${params.modkit_executable_dir}"
log.info " ======================"
log.info ""


// Workflow! Bread and butter of this thing

workflow {
    // Batch level processing
    parse_json(params.batch_id, file("${projectDir}/src"))

    // Sample level processing
    samples_ch = parse_json.out.splitCsv( header: false, sep: '\t' )

    merge_bams(samples_ch, params.input_dir)

    align(merge_bams.out, params.input_dir, params.ref_genome)

    modkit(align.out, params.input_dir, params.ref_genome, params.ref_motifs)

    ch3(modkit.out, params.input_dir, params.call_ch3_script, params.ch3_script)

    qc(ch3.out)

    organize_data(qc.out)

    aws_upload_samples(organize_data.out)

    // Collect all results
    all_results = aws_upload_samples.out.collect()

    aws_upload_batch(params.batch_id, all_results)

    api_post(aws_upload_batch.out)
}
