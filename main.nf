#!/usr/bin/env nextflow
/*
========================================================================================
    nf-core/demultiplex
========================================================================================
    Github : https://github.com/nf-core/demultiplex
    Website: https://nf-co.re/demultiplex
    Slack  : https://nfcore.slack.com/channels/demultiplex
----------------------------------------------------------------------------------------
*/

nextflow.enable.dsl = 2

/*
========================================================================================
    GENOME PARAMETER VALUES
========================================================================================
*/

params.fasta                        = WorkflowMain.getGenomeAttribute(params, 'fasta')
params.bismark_refdir               = WorkflowMain.getGenomeAttribute(params, 'bismark')

/*
========================================================================================
    VALIDATE & PRINT PARAMETER SUMMARY
========================================================================================
*/

WorkflowMain.initialise(workflow, params, log)

/*
========================================================================================
    NAMED WORKFLOW FOR PIPELINE
========================================================================================
*/

include { DEMULTIPLEX } from './workflows/demultiplex'

//
// WORKFLOW: Run main nf-core/demultiplex analysis pipeline
//
workflow NFCORE_DEMULTIPLEX {
    DEMULTIPLEX ()
}

/*
========================================================================================
    RUN ALL WORKFLOWS
========================================================================================
*/

//
// WORKFLOW: Execute a single named workflow for the pipeline
// See: https://github.com/nf-core/rnaseq/issues/619
//
workflow {
    NFCORE_DEMULTIPLEX ()
}

/*
========================================================================================
    THE END
========================================================================================
*/
