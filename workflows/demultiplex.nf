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
target_bed            = params.target_bed            ? Channel.fromPath(params.target_bed).collect()            : Channel.empty()
ch_input_sample       = extract_csv(file(params.input, checkIfExists: true ))


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

include { MULTIQC                     } from '../modules/nf-core/multiqc/main'
include { CAT_FASTQ                   } from '../modules/nf-core/cat/fastq/main'
include { CUSTOM_DUMPSOFTWAREVERSIONS } from '../modules/nf-core/custom/dumpsoftwareversions/main'

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

    ch_input_sample
        .map{ meta, fastq_1, fastq_2 ->
                meta.id = meta.patient + "_" + meta.sample
                [ meta, fastq_1, fastq_2] }         
        .groupTuple(by: [0])
        .branch {
            meta, fastq_1, fastq_2->
                single  : fastq_1.size() == 1
                    return [ meta, [ fastq_1.flatten(), fastq_2.flatten() ].flatten() ]
                multiple: fastq_1.size() > 1
                    return [ meta, [ fastq_1.flatten(), fastq_2.flatten() ].flatten() ]
        }
        .set { ch_fastq }
        
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

    METHYLATION (prepped_reads,
                bismark_refdir,
                methylated_control,
                unmethylated_control,
                target_bed
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
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
// Function to extract information (meta data + file(s)) from csv file(s)
def extract_csv(csv_file) {
    // check file is not empty
    file(csv_file).withReader('UTF-8') { reader ->
        if (reader.readLine() == null) {
            log.error "CSV file is empty"
            return null
        }
    }
    // read csv file
    Channel.of(csv_file).splitCsv(header: true)
    .map { row ->
        if (!(row.patient && row.sample)) log.warn "Missing or unknown field in csv file header"
        [[row.patient.toString(), row.sample.toString()], row]
    }
    .groupTuple()
    .map { meta, rows ->
        size = rows.size()
        [rows, size]
        }.transpose()
          //A Transpose Function takes a collection of columns and returns a collection of rows.
          //The first row consists of the first element from each column. Successive rows are constructed similarly.
          //def result = [['a', 'b'], [1, 2], [3, 4]].transpose()
          //assert result == [['a', 1, 3], ['b', 2, 4]]
            .map{
            row, num_lanes ->
            def meta = [:]
            if (row.patient) meta.patient = row.patient.toString()
            if (row.sample)  meta.sample  = row.sample.toString()
            if (row.sex)  meta.sex  = row.sex.toString()
                else meta.sex = "NA"
            if (row.status)  meta.status  = row.status.toString()
                else meta.status = 0
            if (row.fastq_1) {
                meta.patient  = row.patient.toString()
                meta.sample   = row.sample.toString()
                def fastq_1 = file(row.fastq_1, checkIfExists: true)
                def fastq_2 = file(row.fastq_2, checkIfExists: true)
                //Don't use a random element for ID, it breaks resuming
                meta.data_type   = "fastq"
                return [meta, fastq_1, fastq_2]
                }
            }
            
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
