nextflow.preview.dsl = 2

/*
=================================
          PRINT HELP
=================================
*/

def json_schema = "$baseDir/nextflow_schema.json"
if (params.help) {
    def command = "nextflow run nf-core/rnaseq --input samplesheet.csv --genome GRCh37 -profile docker"
    log.info Schema.params_help(workflow, params, json_schema, command)
    exit 0
}

/*
=================================
       PARAMETER SUMMARY
=================================
*/

def summary_params = Schema.params_summary_map(workflow, params, json_schema)
log.info Schema.params_summary_log(workflow, params, json_schema)

/*
=================================
       PARAMETER CHECKS
=================================
*/

Checks.aws_batch(workflow, params) // Check AWS batch settings
Checks.hostname(workflow, params, log)  // Check the hostnames against configured profiles

// MultiQC - Stage config files

multiqc_config = file("$baseDir/assets/multiqc_config.yaml", checkIfExists: true)
multiqc_custom_config = params.multiqc_config ? Channel.fromPath(params.multiqc_config, checkIfExists: true) : Channel.empty()
output_docs = file("$baseDir/docs/output.md", checkIfExists: true)
output_docs_images = file("$baseDir/docs/images/", checkIfExists: true)


// params summary for MultiQC
workflow_summary = Schema.params_summary_multiqc(workflow, summary_params)
workflow_summary = Channel.value(workflow_summary)

// Has the run name been specified by the user?
// This has the bonus effect of catching both -name and --name

run_name = params.name
if (!(workflow.runName ==~ /[a-z]+_[a-z]+/)) {
    run_name = workflow.runName
}
/*
================================================================================
                     UPDATE MODULES OPTIONS BASED ON PARAMS
================================================================================
*/
modules = params.modules
/*

/*
================================================================================
                               CHECKING REFERENCES
================================================================================
*/

/*
 * TODO check /scratch/DMP/EVGENMOD/gcresswell/MolecularClocks/genomes/ 
 */

params.refdir              = params.genome ? params.genomes[params.genome]. '/scratch/DMP/EVGENMOD/gcresswell/MolecularClocks/genomes/'        ?: false : false
params.methylated_refdir   = workflow.projectDir + '/genome/RRBS_methylated_control'
params.unmethylated_refdir = workflow.projectDir + '/genome/RRBS_unmethylated_control'
file("${params.outdir}/no_file").text = "no_file\n"

include {SAMPLESHEET_CHECK}     from 'modules/local/process/samplesheet_check'
include { FASTQC }              from 'modules/nf-core/software/fastqc/main'

/*
 * Create a channel for input read files
 */

ch_reads = Channel.fromFilePairs(params.reads, size: params.single_end ? 1 : 2)
                  .ifEmpty { exit 1, "Cannot find any reads matching: ${params.reads}\nNB: Path needs to be enclosed in quotes!\nIf this is single-end data, please specify --single_end on the command line." }


workflow {
    // pseudo code
    // when not de-multiplexing
    // if demultiplex 
    // run demultiplex
    // create samplesheet
    
    FASTQC(SAMPLESHEET_CHECK.out)
}