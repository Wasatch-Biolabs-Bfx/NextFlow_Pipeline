/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { PARSE_JSON         } from '../modules/local/parse_json'
include { MERGE_BAMS         } from '../modules/local/merge_bams'
include { ALIGN              } from '../modules/local/align'
include { MODKIT             } from '../modules/local/modkit'
include { CH3                } from '../modules/local/ch3'
include { QC                 } from '../modules/local/qc'
include { ORGANIZE_DATA      } from '../modules/local/organize_data'
include { AWS_UPLOAD_SAMPLES } from '../modules/local/aws_upload_samples'
include { AWS_UPLOAD_BATCH   } from '../modules/local/aws_upload_batch'
include { API_POST           } from '../modules/local/api_post'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow WBL_PIPELINE {

    take:
    input_dir    // path: Input directory containing batch data
    batch_id     // val:  Batch identifier

    main:

    ch_versions = Channel.empty()

    //
    // MODULE: Parse JSON from API to get sample information
    //
    PARSE_JSON (
        batch_id,
        file("${projectDir}/src")
    )
    ch_versions = ch_versions.mix(PARSE_JSON.out.versions)

    //
    // Create sample channel from parsed TSV
    //
    ch_samples = PARSE_JSON.out.samples_tsv
        .splitCsv(header: false, sep: '\t')
        .map { row ->
            def (test_type, barcode, julian_id, req_number) = row
            return tuple(test_type, barcode, julian_id, req_number)
        }

    //
    // MODULE: Merge BAM files for each sample
    //
    MERGE_BAMS (
        ch_samples,
        input_dir
    )
    ch_versions = ch_versions.mix(MERGE_BAMS.out.versions.first())

    //
    // MODULE: Align reads to reference genome (conditional)
    //
    ch_aligned = Channel.empty()
    if (params.align == true || params.modification == true) {
        ALIGN (
            MERGE_BAMS.out.sample_info,
            input_dir,
            params.ref_genome
        )
        ch_versions = ch_versions.mix(ALIGN.out.versions.first())
        ch_aligned = ALIGN.out.sample_info
    } else {
        ch_aligned = MERGE_BAMS.out.sample_info
    }

    //
    // MODULE: Extract methylation calls (conditional)
    //
    ch_modkit = Channel.empty()
    if (params.modification == true) {
        MODKIT (
            ch_aligned,
            input_dir,
            params.ref_genome,
            params.ref_motifs
        )
        ch_versions = ch_versions.mix(MODKIT.out.versions.first())
        ch_modkit = MODKIT.out.sample_info
    } else {
        ch_modkit = ch_aligned
    }

    //
    // MODULE: Create CH3 archives (conditional)
    //
    ch_ch3 = Channel.empty()
    if (params.modification == true) {
        CH3 (
            ch_modkit,
            input_dir
        )
        ch_versions = ch_versions.mix(CH3.out.versions.first())
        ch_ch3 = CH3.out.sample_info
    } else {
        ch_ch3 = ch_modkit
    }

    //
    // MODULE: Generate QC reports (conditional)
    //
    ch_qc = Channel.empty()
    if (params.align == true || params.modification == true) {
        QC (
            ch_ch3,
            input_dir
        )
        ch_versions = ch_versions.mix(QC.out.versions.first())
        ch_qc = QC.out.sample_info
    } else {
        ch_qc = ch_ch3
    }

    //
    // MODULE: Organize and compress data
    //
    ORGANIZE_DATA (
        ch_qc,
        input_dir
    )
    ch_versions = ch_versions.mix(ORGANIZE_DATA.out.versions.first())

    //
    // MODULE: Upload sample data to AWS S3
    //
    AWS_UPLOAD_SAMPLES (
        ORGANIZE_DATA.out.sample_info
    )
    ch_versions = ch_versions.mix(AWS_UPLOAD_SAMPLES.out.versions.first())

    //
    // Collect all sample results for batch processing
    //
    ch_all_results = AWS_UPLOAD_SAMPLES.out.sample_info.collect()

    //
    // MODULE: Upload batch-level data to AWS S3
    //
    AWS_UPLOAD_BATCH (
        batch_id,
        ch_all_results
    )
    ch_versions = ch_versions.mix(AWS_UPLOAD_BATCH.out.versions)

    //
    // MODULE: Post completion status to API
    //
    // Create a channel with the script
    script_ch = Channel.fromPath("${projectDir}/src/api_post.py")

    API_POST (
        AWS_UPLOAD_BATCH.out.batch_id,
        script_ch
    )
    ch_versions = ch_versions.mix(API_POST.out.versions)

    emit:
    versions = ch_versions                 // channel: [ path(versions.yml) ]

}