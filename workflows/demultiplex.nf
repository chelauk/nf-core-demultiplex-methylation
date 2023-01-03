/*
========================================================================================
    VALIDATE INPUTS
========================================================================================
*/

def summary_params = NfcoreSchema.paramsSummaryMap(workflow, params)

// Validate input parameters
WorkflowDemultiplex.initialise(params, log)

checkPathParamList = [
    params.input,
    params.multiqc_config,
    params.fasta,
    params.bismark_refdir
    ]

for (param in checkPathParamList) { if (param) { file(param, checkIfExists: true) } }
// Check mandatory parameters
if (params.input) { ch_input = file(params.input) } else { exit 1, 'Input samplesheet not specified!' }

/*
========================================================================================
    CONFIG FILES
========================================================================================
*/

ch_multiqc_config        = file("$projectDir/assets/multiqc_config.yaml", checkIfExists: true)
ch_multiqc_custom_config = params.multiqc_config ? Channel.fromPath(params.multiqc_config) : Channel.empty()


// intitialise channels based on params

fasta                 = params.fasta                 ? Channel.fromPath(params.fasta).collect()                 : Channel.empty()
bismark_refdir        = params.bismark_refdir        ? Channel.fromPath(params.bismark_refdir).collect()        : Channel.empty()
methylated_control    = params.methylated_control    ? Channel.fromPath(params.methylated_control).collect()    : Channel.value([])
unmethylated_control  = params.unmethylated_control  ? Channel.fromPath(params.unmethylated_control).collect()  : Channel.value([])
/*
========================================================================================
    IMPORT LOCAL MODULES/SUBWORKFLOWS
========================================================================================
*/

//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//
include { INPUT_CHECK } from '../subworkflows/local/input_check'

/*
========================================================================================
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
========================================================================================
*/

//
// MODULE: Installed directly from nf-core/modules
//

include { MULTIQC                     } from '../modules/nf-core/modules/multiqc/main'
include { CAT_FASTQ                   } from '../modules/nf-core/modules/cat/fastq/main'
include { CUSTOM_DUMPSOFTWAREVERSIONS } from '../modules/nf-core/modules/custom/dumpsoftwareversions/main'

//
// SUBWORKFLOW: Installed from subworkflow
//

include { PREP_SAMPLES                } from '../subworkflows/local/prepare_samples.nf'
include { METHYLATION                 } from '../subworkflows/local/methylation.nf'
/*
========================================================================================
    RUN MAIN WORKFLOW
========================================================================================
*/

// Info required for completion email and summary
def multiqc_report = []

workflow DEMULTIPLEX {

    ch_versions = Channel.empty()

    //
    // SUBWORKFLOW: Read in samplesheet, validate and stage input files
    //
    INPUT_CHECK (ch_input)
    .reads
    .map {
        meta, fastq ->
            meta.id = meta.id.split('_')[0..-2].join('_')
            [ meta, fastq ] }
    .groupTuple(by: [0])
    .branch {
        meta, fastq ->
            single  : fastq.size() == 1
                return [ meta, fastq.flatten() ]
            multiple: fastq.size() > 1
                return [ meta, fastq.flatten() ]
    }
    .set { ch_fastq }
    ch_versions = ch_versions.mix(INPUT_CHECK.out.versions)

    //
    // MODULE: Concatenate FastQ files from same sample if required
    //
    CAT_FASTQ (
        ch_fastq.multiple
    )
    .reads
    .mix(ch_fastq.single)
    .set { ch_cat_fastq }
    ch_versions = ch_versions.mix(CAT_FASTQ.out.versions.first().ifEmpty(null))

    //
    // SUBWORKFLOW: QC and prepare reads for alignment
    //

    PREP_SAMPLES (
        ch_cat_fastq,
        params.skip_fastqc || params.skip_qc,
        params.skip_trimming,
        params.skip_demultiplex
        )
    ch_versions = ch_versions.mix(PREP_SAMPLES.out.versions)

    prepped_reads = PREP_SAMPLES.out.reads
    //
    // run Methylation analysis
    //
//	prepped_reads.view()
	bismark_refdir.view()

    METHYLATION (prepped_reads,
                bismark_refdir,
                methylated_control,
                unmethylated_control
                )

    ch_versions = ch_versions.mix(METHYLATION.out.versions)
    CUSTOM_DUMPSOFTWAREVERSIONS (
        ch_versions.unique().collectFile(name: 'collated_versions.yml')
    )

    //
    // MODULE: MultiQC
    //
    workflow_summary    = WorkflowDemultiplex.paramsSummaryMultiqc(workflow, summary_params)
    ch_workflow_summary = Channel.value(workflow_summary)


    MULTIQC (
        ch_multiqc_config,
        ch_multiqc_custom_config.collect().ifEmpty([]),
        CUSTOM_DUMPSOFTWAREVERSIONS.out.mqc_yml.collect(),
        ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'),
        PREP_SAMPLES.out.fastqc_zip.collect{it[1]}.ifEmpty([]),
        PREP_SAMPLES.out.trim_zip.collect{it[1]}.ifEmpty([]),
        PREP_SAMPLES.out.trim_log.collect{it[1]}.ifEmpty([]),
        METHYLATION.out.alignment_report.collect{it[1]}.ifEmpty([]),
        METHYLATION.out.chh_ob.collect{it[1]}.ifEmpty([]),
        METHYLATION.out.chg_ob.collect{it[1]}.ifEmpty([]),
        METHYLATION.out.cpg_ob.collect{it[1]}.ifEmpty([]),
        METHYLATION.out.mbias.collect{it[1]}.ifEmpty([]),
        METHYLATION.out.chh_ot.collect{it[1]}.ifEmpty([]),
        METHYLATION.out.chg_ot.collect{it[1]}.ifEmpty([]),
        METHYLATION.out.cpg_ot.collect{it[1]}.ifEmpty([]),
    )
    multiqc_report = MULTIQC.out.report.toList()
    ch_versions    = ch_versions.mix(MULTIQC.out.versions)

}

/*
========================================================================================
    COMPLETION EMAIL AND SUMMARY
========================================================================================
*/

workflow.onComplete {
    if (params.email || params.email_on_fail) {
        NfcoreTemplate.email(workflow, params, summary_params, projectDir, log, multiqc_report)
    }
    NfcoreTemplate.summary(workflow, params, log)
}

/*
========================================================================================
    THE END
========================================================================================
*/
